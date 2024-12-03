# frozen_string_literal: true

# app/lib/integrations/job_nimbus/v1/base.rb
module Integrations
  module JobNimbus
    module V1
      class Base
        class JobNimbusRequestError < StandardError; end

        attr_reader :error, :message, :result

        include JobNimbus::V1::Contacts
        include JobNimbus::V1::Estimates
        include JobNimbus::V1::Invoices
        include JobNimbus::V1::Jobs
        include JobNimbus::V1::Tasks
        include JobNimbus::V1::Workorders

        # initialize Integrations::JobNimbus object
        # jn_client = Integrations::JobNimbus::V1::Base.new(String)
        def initialize(api_key = '')
          reset_attributes
          @result  = nil
          @api_key = api_key
        end

        # parse & normalize data from webhook
        # rb_client.parse_webhook(params)
        def parse_webhook(args = {})
          @success = true

          {
            event_status: "#{args.dig(:type)}_#{args.dig(:status_name)}",
            contact:      parse_contact_from_webhook(args),
            estimate:     parse_estimate_from_webhook(args),
            job:          parse_job_from_webhook(args),
            invoice:      parse_invoice_from_webhook(args),
            workorder:    parse_workorder_from_webhook(args),
            task:         parse_task_from_webhook(args)
          }
        end

        def success?
          @success
        end

        private

        def base_api_url
          'https://app.jobnimbus.com'
        end

        def base_api_version
          'api1'
        end

        def jobnimbus_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::JobNimbus::V1::Base.jobnimbus_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if @api_key.blank?
            @error_message = 'JobNimbus API key is required.'
            return @result
          elsif url.blank?
            @error_message = 'JobNimbus API URL is required.'
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
            faraday_result = Faraday.send(faraday_method, url) do |req|
              req.headers['Authorization'] = "Bearer #{@api_key}"
              req.headers['Content-Type']  = 'application/json'
              req.params                   = params if params.present?
              req.body                     = body.to_json if body.present?
            end

            # Rails.logger.info "faraday_result: #{faraday_result.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

            case faraday_result.status
            when 200
              result   = JSON.parse(faraday_result.body)
              @result  = if result.respond_to?(:deep_symbolize_keys)
                           result.deep_symbolize_keys
                         elsif result.respond_to?(:map)
                           result.map(&:deep_symbolize_keys)
                         else
                           result
                         end
              @success = true
            when 401, 404
              @message = "#{faraday_result.reason_phrase}: #{faraday_result.body}"
              @success = false
            else
              @message = "#{faraday_result.reason_phrase}: #{faraday_result.body}"
              @success = false

              error = JobNimbusRequestError.new(faraday_result&.reason_phrase)
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action(error_message_prepend)

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'info',
                  error_code:  faraday_result&.status
                )
                Appsignal.add_custom_data(
                  faraday_body:           faraday_result&.body,
                  faraday_result:         faraday_result&.to_hash,
                  faraday_result_methods: faraday_result&.public_methods.inspect,
                  result:                 @result,
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
          Clients::ApiCall.create(target: 'jobnimbus', client_api_id: @api_key, api_call: error_message_prepend)
        end

        def reset_attributes
          @error       = 0
          @message     = ''
          @success     = false
        end
      end
    end
  end
end
