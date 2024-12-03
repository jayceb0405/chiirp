# frozen_string_literal: true

# app/lib/integrations/doper/v1/dope.rb
module Integrations
  module Doper
    module V1
      # process various API calls to Dope Marketing
      class Dope
        class DopeRequestError < StandardError; end

        attr_reader :error, :faraday_result, :message, :result

        # initialize Integrations::Dope object
        # dp_client = Integrations::Doper::V1::Dope.new(api_key)
        def initialize(api_key)
          reset_attributes
          @result  = nil
          @api_key = api_key
        end

        # call Dope API to start an automation
        # dp_client.automation()
        def automation(args = {})
          reset_attributes
          automation_id = args.dig(:automation_id)
          @result       = {}

          return @result if automation_id.blank? || args.dig(:address_01).blank? || args.dig(:city).blank? || args.dig(:state).blank? || args.dig(:postal_code).blank?

          body = {
            firstName: args.dig(:firstname).to_s,
            lastName:  args.dig(:lastname).to_s,
            address1:  args.dig(:address_01).to_s,
            address2:  args.dig(:address_02).to_s,
            city:      args.dig(:city).to_s,
            state:     args.dig(:state).to_s,
            zip:       args.dig(:postal_code).to_s
          }

          @result = dope_request(
            body:,
            error_message_prepend: 'Integrations::Dope.automation',
            method:                'post',
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/automations/#{automation_id}"
          )
        end

        # call Dope API to retrieve automations
        # dp_client.automations
        def automations
          reset_attributes
          @result = []

          @result = dope_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Dope.automations',
            method:                'get',
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/automations"
          )
        end

        def success?
          @success
        end

        private

        def base_api_url
          'https://dope360.com/api'
        end

        def base_api_version
          'v1'
        end

        def basic_auth
          "Bearer #{@api_key}"
        end

        def dope_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::Dope.dope_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if @api_key.blank?
            @error_message = 'Dope API key is required.'
            return @result
          end

          record_api_call(error_message_prepend)

          success, error, message = Retryable.with_retries(
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
              req.headers['Authorization'] = basic_auth
              req.headers['Content-Type']  = 'application/json'
              req.params                   = params if params.present?
              req.body                     = body.to_json if body.present?
            end

            case @faraday_result.status
            when 200
              result   = JSON.parse(@faraday_result.body)
              @result  = if result.respond_to?(:deep_symbolize_keys)
                           result.deep_symbolize_keys
                         elsif result.respond_to?(:map)
                           result.map(&:deep_symbolize_keys)
                         else
                           result
                         end
              @success = true
            when 401, 404
              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"
              @success = false
            else
              @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{@faraday_result&.body}"
              @success = false

              error = DopeRequestError.new(@message)
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action(error_message_prepend)

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'info',
                  error_code:  @faraday_result.status
                )
                Appsignal.add_custom_data(
                  faraday_reason_phrase:  @faraday_result&.reason_phrase,
                  faraday_result:         @faraday_result&.to_hash,
                  faraday_result_body:    JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result&.body) : @faraday_result&.body,
                  faraday_result_methods: @faraday_result&.methods.inspect,
                  file:                   __FILE__,
                  line:                   __LINE__
                )
              end
            end
          end

          @success = false unless success
          @error   = error
          @message = message if message.present?

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'dope_marketing', client_api_id: @api_key, api_call: error_message_prepend)
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
