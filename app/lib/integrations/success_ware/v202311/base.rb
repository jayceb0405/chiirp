# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/base.rb
module Integrations
  module SuccessWare
    module V202311
      class Base
        attr_reader :credentials, :error, :faraday_result, :message, :result

        include SuccessWare::V202311::Invoices
        include SuccessWare::V202311::Jobs
        include SuccessWare::V202311::LeadSources
        include SuccessWare::V202311::Products
        include SuccessWare::V202311::Quotes
        include SuccessWare::V202311::Requests
        include SuccessWare::V202311::ServiceAccounts
        include SuccessWare::V202311::Users
        include SuccessWare::V202311::Visits

        PAGE_SIZE = 500

        # initialize SuccessWare
        # sw_client = Integrations::SuccessWare::V202311::Base.new()
        #   (req) credentials: (String)
        def initialize(credentials)
          reset_attributes
          @result      = nil
          @credentials = credentials.symbolize_keys
        end

        # call Successware API to disconnect account
        # sw_client.disconnect_account
        def disconnect_account
          reset_attributes
          @result = {}

          body = {
            query: <<-GRAPHQL.squish
              mutation {
                appDisconnect {
                  app {
                    id
                  }
                  userErrors {
                    message
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Base.disconnect_account',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :appDisconnect, :userErrors) : nil) || []
        end

        # refresh Successware access_token using user_name & password
        # sw_client.refresh_access_token(user_name, password)
        #   (req) user_name: (String)
        #   (req) password:     (String)
        def refresh_access_token
          reset_attributes
          @result = {}

          if @credentials.dig(:user_name).blank?
            @message = 'Authorization user name is required!'
            return @result
          elsif @credentials.dig(:password).blank?
            @message = 'Authorization password is required!'
            return @result
          end

          @success, @error, @message = Retryable.with_retries(
            rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
            error_message_prepend: 'Integrations::SuccessWare::V202311::Base.refresh_access_token',
            current_variables:     {
              user_name:   @credentials.dig(:user_name),
              password:    @credentials.dig(:password),
              parent_file: __FILE__,
              parent_line: __LINE__
            }
          ) do
            @faraday_result = Faraday.send(:post, access_token_url) do |req|
              req.body = {
                username: @credentials.dig(:user_name),
                password: @credentials.dig(:password)
              }.to_json
              req.headers['Content-Type'] = 'application/json'
            end
          end

          case @faraday_result&.status
          when 200
            @result = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
          else
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @success = false
          end

          JsonLog.info 'Integrations::SuccessWare::V202311::Base.refresh_access_token', { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        # request access_token from Successware
        # sw_client.request_access_token(code)
        #   (req) code: (String)
        def request_access_token(code = '')
          reset_attributes
          @result = {}

          if code.blank?
            @message = 'Authorization code is required!'
            return @result
          end

          @success, @error, @message = Retryable.with_retries(
            rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
            error_message_prepend: 'Integrations::SuccessWare::V202311::Base.request_access_token',
            current_variables:     {
              code:,
              parent_file: __FILE__,
              parent_line: __LINE__
            }
          ) do
            @faraday_result = Faraday.send(:post, access_token_url) do |req|
              req.params = {
                client_id:       Rails.application.credentials[:successware][:client_id],
                client_password: Rails.application.credentials[:successware][:password],
                grant_type:      'authorization_code',
                code:
              }
            end
          end

          case @faraday_result&.status
          when 200
            @result = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
          else
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @success = false
          end

          JsonLog.info 'Integrations::SuccessWare::V202311::Base.request_access_token', { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        def success?
          @success
        end

        def valid_credentials?
          @credentials.dig(:access_token).present? && @credentials.dig(:user_name).present? && @credentials.dig(:password).present? && @credentials.dig(:expires_at).present? && @credentials.dig(:expires_at) > 1.minute.from_now
        end

        private

        def access_token_url
          'https://publicapi-uat.successwareg2.com/api/login'
        end

        def api_url
          'https://publicapi-uat.successwareg2.com/api/graphql'
        end

        def hash_to_graphql(hash)
          " { #{hash.map { |k, v| "#{k}: #{v.is_a?(Hash) ? self.hash_to_graphql(v) : v.inspect.sub(%r{^:}, '')}" }.join(', ').strip} } "
        end

        def array_to_graphql(array)
          " [ #{array.map do |a|
                  if a.is_a?(Hash)
                    self.hash_to_graphql(a)
                  else
                    a.is_a?(Array) ? self.array_to_graphql(a) : a.inspect
                  end
                end.join(', ').strip} ] "
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'successware', client_api_id: @credentials.dig(:company_no), api_call: error_message_prepend)
        end

        def reset_attributes
          @end_cursor     = ''
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @more_results   = false
          @success        = false
        end

        # successware_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::SuccessWare.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def successware_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::SuccessWare::V202311::Base.successware_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if url.blank?
            @message = 'Successware API URL is required.'
            return @result
          elsif @credentials.dig(:access_token).blank?
            @message = 'Successware access token is required.'
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
              req.headers['Authorization']            = "Bearer #{@credentials.dig(:access_token)}"
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

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end

        def sleep_before_throttling(result, expected_cost = nil)
          throttle_status = result.dig(:cost, :throttleStatus) || {}
          currently_available = throttle_status.dig(:currentlyAvailable).to_i
          max_available = throttle_status.dig(:maximumAvailable).to_i
          restore_rate = throttle_status.dig(:restoreRate).to_i
          sleep_time = 0

          expected_cost = max_available * 0.6 if expected_cost.blank?

          if currently_available <= expected_cost
            sleep_time = ((max_available - currently_available) / restore_rate).ceil
            sleep(sleep_time)
          end

          JsonLog.info 'Successware sleep_time', { sleep_time: }
          sleep_time
        end
      end
    end
  end
end
