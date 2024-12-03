# frozen_string_literal: true

# app/lib/notifications/one_signal/v1/base.rb
module Notifications
  module OneSignal
    module V1
      class Base
        class OneSignalRequestError < StandardError; end

        attr_reader :error, :faraday_result, :message, :result

        # os_client = Notifications::OneSignal::V1::Base.new(user_ids)
        #   (req) user_ids: (Array)
        def initialize(user_ids)
          reset_attributes
          @user_ids = user_ids
          @result   = nil
        end

        # os_client.send_push()
        #   (req) content: (String)
        #   (opt) title:   (String)
        #   (opt) url:     (String)
        def send_push(args = {})
          reset_attributes
          @result = {}

          if args.dig(:content).blank?
            @success = false
            @content = 'A message is required.'
            return {}
          end

          body = {
            app_id:,
            contents: { en: args.dig(:content) || '' },
            headings: { en: args.dig(:title) || '' },
            isAnyWeb: true
          }

          body[:url] = args[:url].to_s if args.dig(:url).present?

          if @user_ids.is_a?(Array) && @user_ids.present?
            body[:include_external_user_ids]     = @user_ids.map(&:to_s)
            body[:channel_for_external_user_ids] = 'push'
          else
            body[:included_segments] = ['Subscribed Users']
          end

          one_signal_request(
            body:,
            error_message_prepend: 'Notifications::OneSignal::V1::Base.send_push',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{one_signal_base_url}/notifications"
          )

          @result
        end

        def success?
          @success
        end

        private

        def app_id
          Rails.application.credentials[:one_signal][:app_id]
        end

        def api_key
          Rails.application.credentials[:one_signal][:api_key]
        end

        def one_signal_base_url
          'https://onesignal.com/api/v1'
        end

        # one_signal_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::OneSignal::V1::Base.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def one_signal_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Notifications::OneSignal::V1::Base.one_signal_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          loop do
            redos ||= 0

            @success, @error, @message = Retryable.with_retries(
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
              @faraday_result = Faraday.send(faraday_method, url) do |req|
                req.headers['Authorization']            = "Basic #{api_key}"
                req.headers['Content-Type']             = 'application/json'
                req.headers['Accept']                   = 'application/json'
                req.params                              = params if params.present?
                req.body                                = body.to_json if body.is_a?(Hash)
              end
            end

            # Rails.logger.info "@faraday_result: #{@faraday_result.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

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

              @success = @result.dig(:recipients).to_i.positive?
              @message = @result.dig(:recipients).to_i.positive? ? '' : @result.dig(:errors)&.first
            when 503 # Service Unavailable

              if (redos += 1) < 5
                # JsonLog.info error_message_prepend, { redo: redos, faraday_result: @faraday_result }
                Rails.logger.info "#{error_message_prepend}: #{{ redos:, success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"
                sleep ProcessError::Backoff.full_jitter(redos:)
                redo
              end

              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"

              error = OneSignalRequestError.new(@faraday_result&.reason_phrase)
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action(error_message_prepend)

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'info',
                  error_code:  @faraday_result&.status
                )
                Appsignal.add_custom_data(
                  faraday_result:         @faraday_result&.to_hash,
                  faraday_result_methods: @faraday_result&.public_methods.inspect,
                  result:                 @result,
                  result_body:            @faraday_result&.body,
                  file:                   __FILE__,
                  line:                   __LINE__
                )
              end
            else
              @error   = @faraday_result&.status
              @message = @faraday_result&.reason_phrase
              @result  = args.dig(:default_result)
              @success = false

              error = OneSignalRequestError.new(@message)
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
                  result:                 @result,
                  result_body:            @faraday_result&.body,
                  file:                   __FILE__,
                  line:                   __LINE__
                )
              end
            end

            break
          end

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
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
