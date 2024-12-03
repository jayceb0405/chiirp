# frozen_string_literal: true

# app/lib/integrations/vital_ly/v2024/base.rb
module Integrations
  module VitalLy
    module V2024
      class Base
        attr_reader :error, :faraday_result, :message, :result, :success
        alias success? success

        include VitalLy::V2024::Accounts
        include VitalLy::V2024::Notes
        include VitalLy::V2024::Users

        # initialize Vitally Library
        # vt_client = Integrations::VitalLy::V2024::Base.new
        def initialize
          reset_attributes
          @result = nil
        end

        private

        def api_url
          'https://chiirp.rest.vitally.io'
        end

        def auth_token
          Rails.application.credentials[:vitally][:auth_token]
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'vitally', client_api_id: 1, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end

        def secret_token
          Rails.application.credentials[:vitally][:secret_token]
        end

        # vitally_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::VitalLy::Base.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def vitally_request(args = {})
          reset_attributes
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::VitalLy::Base.vitally_request'
          @result               = args.dig(:default_result)

          if self.secret_token.blank?
            @message = 'Vitally secret token is required.'
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
            @faraday_result = Faraday.send((args.dig(:method) || 'get').to_s, "#{api_url}/#{args.dig(:url)}") do |req|
              req.headers['Authorization'] = "Basic #{auth_token}"
              req.headers['Content-Type']  = 'application/json'
              req.params                   = args[:params] if args.dig(:params).present?
              req.body                     = args[:body].to_json if args.dig(:body).present?
            end

            @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
            result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

            case @faraday_result&.status
            when 200, 204
              @error   = @faraday_result.status unless @faraday_result.status == 200
              @success = !result_body.nil? || @faraday_result.status == 204
              @result  = if result_body.respond_to?(:deep_symbolize_keys)
                           result_body.deep_symbolize_keys
                         elsif result_body.respond_to?(:map)
                           result_body.map(&:deep_symbolize_keys)
                         elsif result_body.nil? && @faraday_result.status == 204
                           args.dig(:default_result)
                         else
                           result_body
                         end
            when 400, 401, 404, 409, 429
              @error   = @faraday_result&.status
              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('error')}"
              @success = false
              @result  = args.dig(:default_result)
            else
              @error   = @faraday_result&.status
              @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('error')}"
              @success = false
              @result  = args.dig(:default_result)
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
end
