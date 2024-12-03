# frozen_string_literal: true

# app/lib/integrations/zapier/base.rb
module Integrations
  module Zapier
    class Base
      # send webhooks to Zapier

      # send a json hash to Zapier
      # Integrations::Zapier.new.zapier_request()
      #   (req) body:                    (Hash)
      #   (opt) error_message_prepend:   'Integrations::ServiceTitan::Base.xxx',
      #   (req) url:                     (String)
      #   (req) user_api_integration_id: (Integer)
      def zapier_request(**args)
        response = { success: false, body: '', error: '', message: '' }

        return response unless Integer(args.dig(:user_api_integration_id), exception: false).present? && args.dig(:body).is_a?(Hash) && args[:body].present? &&
                               args.dig(:url).to_s.present?

        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::Zapier::Base.zapier_request'

        begin
          faraday_result = Faraday.post(args[:url].to_s) do |req|
            req.headers['Content-Type']  = 'application/json'
            req.body                     = args[:body].to_json
          end

          Rails.logger.info "#{error_message_prepend}: #{{ args: args.inspect, status: faraday_result.status, reason_phrase: faraday_result.reason_phrase, body: faraday_result.body.inspect }} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          if faraday_result.status.to_i == 410 && args[:user_api_integration_id].to_i.positive? && (user_api_integration = UserApiIntegration.find_by(id: args[:user_api_integration_id].to_i))
            # Zapier subscription was deleted / delete UserApiIntegration
            user_api_integration.destroy
          end

          response[:success]       = [200..299].include?(faraday_result.status.to_i)
          response[:body]          = faraday_result.body.to_s
          response[:error] = faraday_result.status.to_i
          response[:message] = faraday_result.reason_phrase.to_s
        rescue Faraday::TimeoutError => e
          # Faraday timed out attempting to connect with Zapier
          response[:error] = ''
          response[:message] = "#{error_message_prepend}: ReadTimeout."

          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action(error_message_prepend)

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'error',
              error:       0
            )
            Appsignal.add_custom_data(
              faraday_result: faraday_result&.to_hash,
              response:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        rescue StandardError => e
          # something happened
          response[:error] = defined?(faraday_result) && defined?(faraday_result.status) ? faraday_result.status : ''
          response[:message] = defined?(faraday_result) && defined?(faraday_result.reason_phrase) ? faraday_result.reason_phrase : 'Zapier::Error: Unknown.'

          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action(error_message_prepend)

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'error',
              error:       0
            )
            Appsignal.add_custom_data(
              faraday_result: faraday_result&.to_hash,
              response:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        end

        response
      end
    end
  end
end
