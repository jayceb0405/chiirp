# frozen_string_literal: true

# Integrations::ThumbTack::V2::Base.new(cai.credentials)
# app/lib/integrations/thumb_tack/v2/base.rb
module Integrations
  module ThumbTack
    module V2
      class Base < Integrations::ThumbTack::Base
        include ThumbTack::V2::Account

        private

        def client_id
          Rails.application.credentials[:thumbtack][:client_id]
        end

        def client_secret
          Rails.application.credentials[:thumbtack][:client_secret]
        end

        def api_domain(endpoint)
          case Rails.env
          when 'development'
            'staging-pro-api.thumbtack.com'
          when 'production'
            'pro-api.thumbtack.com'
          end
        end

        def api_scheme
          'https://'
        end

        def api_version
          'v2'
        end

        def record_api_call(error_message_prepend)
          ::Clients::ApiCall.create(target: 'thumbtack', client_api_id: @refresh_token, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end

        # https://api.thumbtack.com/docs
        # thumbtack_request(
        #   authorization:         String,
        #   auth_type:             String,
        #   body:                  Hash,
        #   default_result:        @result,
        #   endpoint:              String,
        #   error_message_prepend: 'Integrations::ThumbTack.xxx',
        #   method:                String,
        #   params:                Hash,
        # )
        def thumbtack_request(args = {})
          reset_attributes
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::ThumbTack::V2::Base.thumbtack_request'
          @result               = args.dig(:default_result)

          if args.dig(:endpoint).blank?
            @message = 'ThumbTack API endpoint is required.'
            return @result
          end

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
              parent_endpoint:              args[:endpoint],
              parent_file:                  __FILE__,
              parent_line:                  __LINE__
            }
          ) do
            @faraday_result = Faraday.send((args.dig(:method) || 'get').to_s, "#{api_scheme}#{api_domain(args[:endpoint])}/#{api_version}/#{args[:endpoint]}") do |req|
              req.headers['Authorization']            = "#{args.dig(:auth_type).presence || 'Bearer'} #{args.dig(:authorization).presence || @access_token}"
              req.headers['Content-Type']             = 'application/json'
              req.headers['Accept']                   = 'application/json'
              req.params                              = args[:params] if args.dig(:params).present?
              req.body                                = args[:body].to_json if args.dig(:body).present?
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

          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          @result
        end
      end
    end
  end
end
