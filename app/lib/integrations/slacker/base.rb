# frozen_string_literal: true

# app/lib/integrations/slacker/base.rb
module Integrations
  module Slacker
    class Base
      attr_reader :error, :faraday_result, :message, :result, :success

      include Slacker::Channels
      include Slacker::Messages
      include Slacker::Users

      # initialize Integrations::Slacker object
      # user_id = xx
      # user = User.find(user_id); slack_client = Integrations::Slacker::Base.new(user&.user_api_integrations&.find_by(target: 'slack', name: '')&.token)
      def initialize(client_token)
        reset_attributes
        @result       = nil
        @success      = true
        @client_token = client_token.to_s
      end

      # call Slack API for info on current user
      # slack_client.me
      def me
        reset_attributes

        slack_request(
          body:                  nil,
          error_message_prepend: 'Integrations::Slacker::Base.me',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_api_url}/users.profile.get"
        )

        if @success && @result.is_a?(Hash)
          response = @result.dig(:profile) || {}
        else
          response = {}
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end

      # call Slack API to revoke an OAuth token
      # slack_client.oauth_revoke
      def oauth_revoke
        reset_attributes

        slack_request(
          body:                  nil,
          error_message_prepend: 'Integrations::Slacker::Base.oauth_test',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_api_url}/auth.revoke"
        )

        if @success && @result.is_a?(Hash)
          response = @result.dig(:revoked).to_bool
        else
          response = false
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end

      # call Slack API to test an OAuth token
      # slack_client.oauth_test
      def oauth_test
        reset_attributes

        slack_request(
          body:                  nil,
          error_message_prepend: 'Integrations::Slacker::Base.oauth_test',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_api_url}/auth.test"
        )

        if @success && @result.is_a?(Hash)
          response = @result
        else
          response = {}
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end

      private

      def base_api_url
        'https://slack.com/api'
      end

      def basic_auth
        @client_token
      end

      def normalize_channel_name(name)
        name.to_s.strip.tr(' ', '_').tr('^A-Za-z0-9_', '-').downcase
      end

      def record_api_call(error_message_prepend)
        Clients::ApiCall.create(target: 'slack', client_api_id: basic_auth, api_call: error_message_prepend)
      end

      def reset_attributes
        @error       = 0
        @message     = ''
        @success     = false
      end

      # slack_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::Slacker::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String
      # )
      def slack_request(args = {})
        reset_attributes
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::Slacker::Base.slack_request'
        @result               = args.dig(:default_result)

        if basic_auth.blank?
          @error   = 0
          @message = 'Slack token is required.'
          @success = false
          return @result
        end

        record_api_call(error_message_prepend)

        success, error, message = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError],
          error_message_prepend:,
          current_variables:     {
            parent_body:                  args.dig(:body),
            parent_error_message_prepend: args.dig(:error_message_prepend),
            parent_method:                args.dig(:method),
            parent_params:                args.dig(:params),
            parent_result:                args.dig(:default_result),
            parent_url:                   args.dig(:url),
            parent_file:                  __FILE__,
            parent_line:                  __LINE__
          }
        ) do
          @faraday_result = Faraday.send((args.dig(:method) || 'get').to_s, args.dig(:url).to_s) do |req|
            req.headers['Authorization'] = "Bearer #{basic_auth}"
            req.headers['Content-Type']  = 'application/json; charset=utf-8'
            req.params                   = args[:params] if args.dig(:params).present?
            req.body                     = args[:body].to_json if args.dig(:body).present?
          end

          @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
          result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

          case @faraday_result&.status
          when 200
            @result  = if result_body.respond_to?(:deep_symbolize_keys)
                         result_body.deep_symbolize_keys
                       elsif result_body.respond_to?(:map)
                         result_body.map(&:deep_symbolize_keys)
                       else
                         result_body
                       end
            @success = @result&.dig(:ok)&.to_bool
          when 400
            @error   = 400
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('error').to_s.titleize.capitalize}"
            @success = false
          when 401
            @error   = 401
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('error').to_s.titleize.capitalize}"
            @success = false
          when 404
            @error   = 404
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('error').to_s.titleize.capitalize}"
            @success = false
          when 409
            @error   = 409
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('error').to_s.titleize.capitalize}"
            @success = false
          when 429
            @error   = 429
            @message = 'Too Many Requests'
            @success = false
            @result  = []
          else
            @error   = @faraday_result&.status
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false

            # JsonLog.info error_message_prepend, { args:, faraday_result: @faraday_result, result: @result, result_body: }
            Rails.logger.info "#{error_message_prepend}: #{{ args:, success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"
          end
        end

        @success = false unless success
        @error   = error if error.to_i.positive?
        @message = message if message.present?

        # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
        Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

        @result
      end
    end
  end
end
