# frozen_string_literal: true

# app/lib/credit_card/stripe_api/base.rb
module CreditCard
  module StripeApi
    class Base
      attr_accessor :error, :faraday_result, :message, :result, :success
      alias success? success

      include CreditCard::StripeApi::Cards
      include CreditCard::StripeApi::Charges
      include CreditCard::StripeApi::Customers
      include CreditCard::StripeApi::Prices
      include CreditCard::StripeApi::Products
      include CreditCard::StripeApi::SubscriptionSchedules

      # initialize CreditCard::StripeApi::Base
      # cc_client = CreditCard::StripeApi::Base.new
      def initialize
        Stripe.api_key = stripe_credit_card_secret_key
      end

      private

      def process_error(e, args)
        message    = "#{caller_locations(2, 1).first.path[caller_locations(2, 1).first.path.index('app/lib/') + 8..caller_locations(2, 1).first.path.index('.rb') - 1].titleize.gsub('/', '::').delete(' ')}.#{caller_locations(2, 1).first.base_label} (#{e.class}): #{e.respond_to?(:json_body) ? e.json_body.dig(:error, :message) : e.message}"
        error_code = e.respond_to?(:json_body) ? e.json_body.dig(:error, :code) : 0

        unless %w[card_declined].include?(error_code)
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('CreditCard::StripeApi::Base.process_error')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'info',
              error_code:
            )
            Appsignal.add_custom_data(
              message:,
              file:    __FILE__,
              line:    __LINE__
            )
          end
        end

        if self.private_methods.include?(e.class.to_s.gsub('::', '_').underscore.to_sym)
          send(e.class.to_s.gsub('::', '_').underscore.to_sym, e)
        else
          @error          = 0
          @faraday_result = if e.respond_to?(:json_body)
                              e.json_body
                            else
                              e.respond_to?(:http_body) ? e.http_body : e
                            end
          @message        = "Unknown error. Please contact #{I18n.t('tenant.name')} support. (#{caller_locations(2, 1).first.lineno})"
          @result         = {}
        end
      end

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @result         = nil
        @success        = false
      end

      def stripe_card_error(e)
        # Since it's a decline, Stripe::CardError will be caught
        unless %w[card_declined incorrect_number insufficient_funds do_not_honor].include?(e.json_body.dig(:error, :type).to_s.downcase)
          # report on anything but card declined
          Rails.logger.info "#{caller_locations(3, 1).first.path[caller_locations(3, 1).first.path.index('app/lib/') + 8..caller_locations(3, 1).first.path.index('.rb') - 1].titleize.gsub('/', '::').delete(' ')}.#{caller_locations(3, 1).first.base_label} (Stripe::CardError): #{{ e:, json_body: e.json_body }.inspect} - File: #{caller_locations(3, 1).first.path} - Line: #{caller_locations(3, 1).first.lineno} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        end

        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = e.json_body.dig(:error, :message)
        @result         = {}
      end
      # example Stripe::CardError
      # {
      #   e:          #<Stripe::CardError: (Status 402) (Request req_1Nu9q48gN1e9AU) Your card was declined.>,
      #   json_body: {
      #     error: {
      #       code:            'card_declined',
      #       decline_code:    'do_not_honor',
      #       doc_url:         'https://stripe.com/docs/error-codes/card-declined',
      #       message:         'Your card was declined.',
      #       param:           '',
      #       request_log_url: 'https://dashboard.stripe.com/logs/req_1Nu9q48gN1e9AU?t=1724803365',
      #       type:            'card_error'
      #     }
      #   }
      # }

      def stripe_rate_limit_error(e)
        # too many requests made to the API too quickly
        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = "Processor was busy (#{e.json_body.dig(:error, :message)}). Please try again. (#{caller_locations(3, 1).first.lineno})"
        @result         = {}
      end

      def stripe_invalid_request_error(e)
        # Invalid parameters were supplied to Stripe's API
        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = "Processor did not receive valid data (#{e.json_body.dig(:error, :message)}). Please contact #{I18n.t('tenant.name')} support. (#{caller_locations(3, 1).first.lineno})"
        @result         = {}
      end

      def stripe_authentication_error(e)
        # Authentication with Stripe's API failed
        # (maybe you changed API keys recently)
        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = "Processor could not authenticate data (#{e.json_body.dig(:error, :message)}). Please contact #{I18n.t('tenant.name')} support. (#{caller_locations(3, 1).first.lineno})"
        @result         = {}
      end

      def stripe_api_connection_error(e)
        # Network communication with Stripe failed
        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = "Network communication failure (#{e.json_body.dig(:error, :message)}). Please contact #{I18n.t('tenant.name')} support. (#{caller_locations(3, 1).first.lineno})"
        @result         = {}
      end

      def stripe_stripe_error(e)
        # stripe error
        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = "Unable to complete transaction (#{e.json_body.dig(:error, :message)}). Please contact #{I18n.t('tenant.name')} support. (#{caller_locations(3, 1).first.lineno})"
        @result         = {}
      end

      def standard_error(e)
        # Something else happened, completely unrelated to Stripe
        @error          = e.json_body.dig(:error, :code)
        @faraday_result = e.json_body
        @message        = "Unknown error. Please contact #{I18n.t('tenant.name')} support. (#{caller_locations(3, 1).first.lineno})"
        @result         = {}
      end

      # return the stripe secret key used for this client
      def stripe_credit_card_secret_key
        Rails.application.credentials[:creditcard][:stripe][:secret_key]
      end
    end
  end
end
