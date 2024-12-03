# frozen_string_literal: true

# app/lib/integrations/field_routes/v1/base.rb
module Integrations
  module FieldRoutes
    module V1
      class Base
        attr_reader :error, :faraday_result, :message, :result

        include FieldRoutes::V1::Customers
        include FieldRoutes::V1::Employees
        include FieldRoutes::V1::Offices

        # initialize FieldRoutes
        # fr_client = Integrations::FieldRoutes::V1::Base.new()
        #   (req) credentials: (String)
        def initialize(credentials)
          reset_attributes
          @result       = nil
          @credentials  = credentials&.symbolize_keys
        end

        def success?
          @success
        end

        def valid_credentials?
          @credentials&.dig(:subdomain).present? && @credentials&.dig(:auth_key).present? && @credentials&.dig(:auth_token).present?
        end

        # private

        def api_url
          "https://#{subdomain}.fieldroutes.com/api"
        end

        def auth_key
          @credentials&.dig(:auth_key).to_s
        end

        def auth_token
          @credentials&.dig(:auth_token).to_s
        end

        # fieldroutes_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::FieldRoutes::V1::xxx.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def fieldroutes_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::FieldRoutes::V1::Base.fieldroutes_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params) || {}
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if subdomain.blank?
            @message = 'FieldRoutes API domain is required.'
            return @result
          elsif auth_key.blank?
            @message = 'FieldRoutes API Key is required.'
            return @result
          elsif auth_token.blank?
            @message = 'FieldRoutes API Token is required.'
            return @result
          elsif url.blank?
            @message = 'FieldRoutes API URL is required.'
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
              parent_url:                   args.dig(:url),
              parent_file:                  __FILE__,
              parent_line:                  __LINE__
            }
          ) do
            @faraday_result = Faraday.send(faraday_method, url) do |req|
              req.headers['Authorization']            = "Bearer #{@access_token}"
              req.headers['Content-Type']             = 'application/x-www-form-urlencoded;charset=UTF-8'
              req.headers['Accept']                   = 'application/json'
              req.params                              = params.merge({ authenticationKey: auth_key, authenticationToken: auth_token })
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
              unless @result.dig(:success).to_bool
                if @result.dig(:tokenUsage, :requestsReadInLastMinute).to_i >= @result.dig(:tokenLimits, :limitReadRequestsPerMinute).to_i ||
                   @result.dig(:tokenUsage, :requestsReadToday).to_i >= @result.dig(:tokenLimits, :limitReadRequestsPerDay).to_i
                  @error   = 429
                  @message = @result&.dig(:errorMessage).to_s
                  @result  = args.dig(:default_result)
                  @success = false
                else
                  @error   = 0
                  @message = @result&.dig(:errorMessage).to_s
                  @result  = args.dig(:default_result)
                  @success = false
                end
              end
            else
              @error   = 0
              @message = 'FieldRoutes response is not a Hash.'
              @result  = args.dig(:default_result)
              @success = false
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

          JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        def record_api_call(error_message_prepend)
          ::Clients::ApiCall.create(target: 'fieldroutes', client_api_id: @refresh_token, api_call: error_message_prepend)
        end

        def reset_attributes
          @end_cursor     = ''
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @more_results   = false
          @success        = false
        end

        def subdomain
          @credentials&.dig(:subdomain).to_s
        end
      end
    end
  end
end
