# frozen_string_literal: true

# app/lib/integrations/face_book/base.rb
module Integrations
  module FaceBook
    class Base
      class FacebookRequestError < StandardError; end

      attr_accessor :error, :faraday_result, :message, :page_size, :result, :success

      include FaceBook::Leads
      include FaceBook::Messenger
      include FaceBook::Pages
      include FaceBook::Users

      # initialize Facebook
      # fb_client = Integrations::FaceBook::Base.new()
      #   (opt) fb_user_id: (String)
      #   (opt) token:      (String)
      def initialize(**args)
        reset_attributes
        @fb_user_id = args.dig(:fb_user_id).to_s
        @result     = nil
        @token      = args.dig(:token).to_s
      end

      def success?
        @success
      end

      # validate a User token
      # fb_client.valid_credentials?
      # Integration::Facebook::Base.new(fb_user_id: String, token: String).valid_credentials?
      def valid_credentials?
        reset_attributes
        @result = false

        if @token.empty?
          @message = 'Facebook User token is required'
        elsif user.dig(:id).to_s.blank?
          reset_attributes
          @message = 'User token is not valid'
          @result  = false
        else
          @result = true
        end

        @result
      end

      private

      def api_request_limit
        50
      end

      def api_version
        'v21.0'
      end

      def base_api_url
        'https://graph.facebook.com'
      end

      # facebook_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::Faceboook::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String
      # )
      def facebook_request(args = {})
        reset_attributes
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::FaceBook::Base.facebook_request'
        @result               = args.dig(:default_result)

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
            @success = !result_body.nil?
          when 400, 401, 404, 409, 429
            @error   = @faraday_result&.status
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('error', 'message').to_s.titleize.capitalize} (#{result_body&.dig('error', 'code').to_i}/#{result_body&.dig('error', 'error_subcode').to_i})"
            @success = false
          else
            @error   = @faraday_result&.status
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('error', 'message').to_s.titleize.capitalize} (#{result_body&.dig('error', 'code').to_i}/#{result_body&.dig('error', 'error_subcode').to_i})"
            @success = false

            error = FacebookRequestError.new(@message)
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action(error_message_prepend)

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @error
              )
              Appsignal.add_custom_data(
                faraday_result:         @faraday_result&.to_hash,
                faraday_result_methods: @faraday_result&.methods.inspect,
                result:                 @result,
                result_body:            @faraday_result&.body,
                file:                   __FILE__,
                line:                   __LINE__
              )
            end
          end
        end

        @success = false unless success
        @error   = error if error.to_i.positive?
        @message = message if message.present?

        Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

        @result
      end

      def record_api_call(error_message_prepend)
        Clients::ApiCall.create(target: 'facebook', client_api_id: @fb_user_id, api_call: error_message_prepend) if @fb_user_id.present?
      end

      def reset_attributes
        @error   = 0
        @message = ''
        @success = false
      end
    end
  end
end
