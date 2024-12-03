# frozen_string_literal: true

# app/lib/integrations/call_rail/v3/base.rb
# https://apidocs.callrail.com/
module Integrations
  module CallRail
    module V3
      # process various API calls to CallRail
      class Base
        attr_reader :credentials, :api_key, :webhook_signature_token, :error, :faraday_result, :message, :result
        attr_accessor :account_id, :company_id

        include CallRail::V3::Accounts
        include CallRail::V3::Calls
        include CallRail::V3::Forms
        include CallRail::V3::Tags
        include CallRail::V3::Trackers

        # initialize CallRail
        # cr_client = Integrations::CallRail::V3::Base.new()
        # (req) credentials: (String)
        def initialize(credentials, account_id: nil, company_id: nil)
          reset_attributes
          @result = nil
          @credentials = credentials&.symbolize_keys
          @api_key = @credentials&.dig(:api_key)
          @webhook_signature_token = @credentials&.dig(:webhook_signature_token)
          @account_id = account_id
          @company_id = company_id
        end

        def success?
          @success
        end

        def valid_credentials?
          @api_key.present? && accounts.any?
        end

        private

        def api_url
          'https://api.callrail.com/v3'
        end

        # callrail_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::CallRail::V3.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def callrail_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::CallRail::V3.CallRailRequest'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = "#{api_url}#{args.dig(:url)}"

          if url.blank?
            @message = 'CallRail API URL is required.'
            return @result
          end

          # loop do
          #   redos ||= 0

          record_api_call(error_message_prepend)

          @success, @error, @message = Retryable.with_retries(
            rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
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
            @faraday_result = Faraday.send(faraday_method, url) do |req|
              req.headers['Authorization']            = "Token token=#{@api_key}"
              req.headers['Content-Type']             = 'application/json'
              req.headers['Accept']                   = 'application/json'
              req.params                              = params if params.present?
              req.body                                = body.to_json if body.present?
            end
          end

          case @faraday_result&.status
          when 200
            result   = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
            @result  = if result.respond_to?(:deep_symbolize_keys)
                         result.deep_symbolize_keys
                       elsif result.respond_to?(:map)
                         result.map(&:deep_symbolize_keys)
                       else
                         result
                       end

            if @result.is_a?(Hash)

              case @result.dig(:Code).to_i
              when 404, 405, 411, 412, 500
                @message = @result.dig(:Message).to_s
                @result  = args.dig(:default_result)
                @success = false
              end
            end
          when 401, 404
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = args.dig(:default_result)
            @success = false
          when 403 # Forbidden
            Rails.logger.info "#{error_message_prepend}: #{{ args:, faraday_result: @faraday_result }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          else
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = args.dig(:default_result)
            @success = false

            ProcessError::Report.send(
              error_message: "#{error_message_prepend}: #{@faraday_result&.reason_phrase} (#{@faraday_result&.status}): #{@faraday_result&.body}",
              variables:     {
                args:                   args.inspect,
                faraday_result:         @faraday_result&.inspect,
                faraday_result_methods: @faraday_result&.methods.inspect,
                reason_phrase:          @faraday_result&.reason_phrase.inspect,
                result:                 @result.inspect,
                status:                 @faraday_result&.status.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end

          #   break
          # end

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'callrail', client_api_id: @api_key, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end
      end
    end
  end
end
