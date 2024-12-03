# frozen_string_literal: true

# app/lib/integrations/job_ber/v20220915/base.rb
module Integrations
  module JobBer
    module V20220915
      class Base
        attr_reader :access_token, :credentials, :end_cursor, :error, :expires_at, :faraday_result, :message, :more_results, :refresh_token, :result

        include JobBer::V20220915::Clients
        include JobBer::V20220915::Invoices
        include JobBer::V20220915::Jobs
        include JobBer::V20220915::Products
        include JobBer::V20220915::Quotes
        include JobBer::V20220915::Requests
        include JobBer::V20220915::Users
        include JobBer::V20220915::Visits

        # initialize JobBer
        # jb_client = Integrations::JobBer::V20220915::Base.new()
        #   (req) credentials: (String)
        def initialize(credentials)
          reset_attributes
          @result        = nil
          @credentials   = credentials&.symbolize_keys
          @access_token  = @credentials&.dig(:access_token).to_s
          @refresh_token = @credentials&.dig(:refresh_token).to_s
          @expires_at    = @credentials&.dig(:expires_at)
        end

        # call Jobber API for client account info
        # jb_client.account
        def account
          reset_attributes
          @result = {}

          body = {
            query: <<-GRAPHQL.squish
              query SampleQuery {
                account {
                  id
                  name
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20220915::Base.account',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :account) : nil) || {}
        end

        # call Jobber API to disconnect account
        # jb_client.disconnect_account
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

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20220915::Base.disconnect_account',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :appDisconnect, :userErrors) : nil) || []
        end

        # refresh Jobber access_token using refresh_token
        # jb_client.refresh_access_token(refresh_token)
        #   (req) refresh_token: (String)
        def refresh_access_token(refresh_token = '')
          reset_attributes
          @result = {}

          if refresh_token.blank?
            @message = 'Authorization refresh_token is required!'
            return @result
          end

          @success, @error, @message = Retryable.with_retries(
            rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
            error_message_prepend: 'Integrations::JobBer::V20220915::Base.refresh_access_token',
            current_variables:     {
              refresh_token:,
              parent_file:   __FILE__,
              parent_line:   __LINE__
            }
          ) do
            @faraday_result = Faraday.send(:post, access_token_url) do |req|
              req.params = {
                client_id:     Rails.application.credentials[:jobber][:client_id],
                client_secret: Rails.application.credentials[:jobber][:secret],
                grant_type:    'refresh_token',
                refresh_token:
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

          JsonLog.info 'Integrations::JobBer::V20220915::Base.refresh_access_token', { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        # request access_token & refresh_token from Jobber
        # jb_client.request_access_token(code)
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
            error_message_prepend: 'Integrations::JobBer::V20220915::Base.request_access_token',
            current_variables:     {
              code:,
              parent_file: __FILE__,
              parent_line: __LINE__
            }
          ) do
            @faraday_result = Faraday.send(:post, access_token_url) do |req|
              req.params = {
                client_id:     Rails.application.credentials[:jobber][:client_id],
                client_secret: Rails.application.credentials[:jobber][:secret],
                grant_type:    'authorization_code',
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

          JsonLog.info 'Integrations::JobBer::V20220915::Base.request_access_token', { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        def success?
          @success
        end

        def valid_credentials?
          @access_token.present? && @refresh_token.present? && @expires_at.present? && @expires_at > 1.minute.from_now
        end

        private

        def access_token_url
          'https://api.getjobber.com/api/oauth/token'
        end

        def api_url
          'https://api.getjobber.com/api/graphql'
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

        # jobber_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::JobBer.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def jobber_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::JobBer::V20220915::Base.jobber_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if url.blank?
            @message = 'JobBer API URL is required.'
            return @result
          end

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
              req.headers['Content-Type']             = 'application/json'
              req.headers['Accept']                   = 'application/json'
              req.headers['X-JOBBER-GRAPHQL-VERSION'] = '2022-09-15'
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

        def reset_attributes
          @end_cursor     = ''
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @more_results   = false
          @success        = false
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

          JsonLog.info 'Jobber.sleep_before_throttling', { sleep_time: } if sleep_time.positive?
          sleep_time
        end
      end
    end
  end
end
