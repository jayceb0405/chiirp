# frozen_string_literal: true

# app/lib/integrations/field_pulse/v1/base.rb
module Integrations
  module FieldPulse
    module V1
      class Base
        class FieldpulseRequestError < StandardError; end

        attr_reader :error, :faraday_result, :message, :result

        include FieldPulse::V1::Customers
        include FieldPulse::V1::JobStatusWorkflows
        include FieldPulse::V1::JobStatusWorkflowStatuses
        include FieldPulse::V1::Jobs
        include FieldPulse::V1::LeadSources
        include FieldPulse::V1::Teams
        include FieldPulse::V1::Users

        # Integrations::FieldPulse::V1::Base::IMPORT_BLOCK_COUNT
        IMPORT_BLOCK_COUNT = 50

        # initialize FieldPulse API client
        # fp_client = Integrations::FieldPulse::V1::Base.new()
        #   (req) api_key: (String)
        def initialize(api_key)
          reset_attributes
          @api_key = api_key
          @result  = nil
        end

        def success?
          @success
        end

        def valid_credentials?
          @api_key.present?
        end

        private

        def api_url
          'https://ywe3crmpll.execute-api.us-east-2.amazonaws.com/stage'
        end

        # fieldpulse_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::FieldPulse.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def fieldpulse_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::FieldPulse::V1::Base.fieldpulse_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if url.blank?
            @message = 'FieldPulse API URL is required.'
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
            @faraday_result = Faraday.send(faraday_method, "#{api_url}/#{url}") do |req|
              req.headers['Content-Type']             = 'application/json'
              req.headers['Accept']                   = 'application/json'
              req.headers['x-api-key']                = @api_key
              req.params                              = params if params.present?
              req.body                                = body.to_json if body.present?
            end
          end

          case @faraday_result&.status
            # 200 OK: Everything worked as expected
            # 201 Created: Everything worked as expected
            # 202 Accepted: Authentication is passed
            # 400 Bad Request: The request was unacceptable, often due to missing a required parameter or wrong parameter.
            # 401 Unauthorized: for missing/invalid authentication
            # 404 Not Found: for non-existing resources
            # 422 Unprocessable Entity: authentication validation error
            # 500 Internal Server Error: for server errors
          when 200, 201, 202
            result   = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
            @result  = if result.respond_to?(:deep_symbolize_keys)
                         result.deep_symbolize_keys
                       elsif result.respond_to?(:map)
                         result.map(&:deep_symbolize_keys)
                       else
                         result
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

            error = FieldpulseRequestError.new(@message)
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
                faraday_result_methods: @faraday_result&.public_methods.inspect,
                reason_phrase:          @faraday_result&.reason_phrase,
                url:                    @faraday_result&.respond_to?(:url) ? @faraday_result.url : nil,
                file:                   __FILE__,
                line:                   __LINE__
              )
            end
          end

          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end
        # example FieldPulse response
        # {
        #   status: 200,
        #   body: {
        #     error:            false,
        #     total_results:    2,
        #     response:         []
        #   },
        #   response_headers: {
        #     date:             "Tue, 01 Oct 2024 19:25:28 GMT",
        #     content-type:     "application/json",
        #     content-length:   "358",
        #     connection:       "keep-alive",
        #     x-amzn-requestid: "9301b606-e871-40f5-a82b-738fe06d5d6b",
        #     x-amz-apigw-id:   "e_DqUG5-iYcEdpQ=",
        #     x-amzn-trace-id:  "Root=1-66fc4ca8-40ce430d392860486fd39a3e"
        #   },
        #   url:              "https://ywe3crmpll.execute-api.us-east-2.amazonaws.com/stage/users?limit=100\u0026page=1"
        # }

        def record_api_call(error_message_prepend)
          ::Clients::ApiCall.create(target: 'fieldpulse', client_api_id: @api_key, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end

        def sleep_before_throttling(result, expected_cost = nil)
          throttle_status = result&.dig(:cost, :throttleStatus) || {}
          currently_available = throttle_status.dig(:currentlyAvailable).to_i
          max_available = throttle_status.dig(:maximumAvailable).to_i
          restore_rate = (throttle_status.dig(:restoreRate) || 1).to_i
          sleep_time = 0

          expected_cost = max_available * 0.6 if expected_cost.blank?

          if currently_available <= expected_cost
            sleep_time = [((max_available - currently_available) / restore_rate).ceil, 5].max
            sleep(sleep_time)
          end

          Rails.logger.info "Fieldpulse.sleep_before_throttling: #{{ sleep_time: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }" if sleep_time.positive?
          sleep_time
        end
      end
    end
  end
end
