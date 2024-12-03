# frozen_string_literal: true

# app/lib/credit_card/stripe_api/cards.rb
module CreditCard
  module StripeApi
    module Cards
      # get credit card info from single use token using Stripe
      # result = CreditCard::StripeApi::Base.new.card()
      #   (req) card_id:   (String)
      #   (req) client_id: (String)
      def card(args)
        reset_attributes

        if args.dig(:card_id).to_s.empty?
          @result  = {}
          @message = 'Card token is required'
          return @result
        elsif args.dig(:client_id).to_s.empty?
          @result  = {}
          @message = 'Client token is required'
          return @result
        end

        begin
          if args[:card_id].to_s[0, 4].casecmp?('card')
            normalize_card_model(Stripe::Customer.retrieve_source(args[:client_id].to_s, args[:card_id].to_s), args[:client_id].to_s)
          elsif args[:card_id].to_s[0, 3].casecmp?('tok')
            normalize_card_model(Stripe::Token.retrieve(args[:card_id].to_s), args[:client_id].to_s)
          end
        rescue Stripe::CardError => e
          process_error(e, args)
        rescue Stripe::RateLimitError => e
          process_error(e, args)
        rescue Stripe::InvalidRequestError => e
          process_error(e, args)
        rescue Stripe::AuthenticationError => e
          process_error(e, args)
        rescue Stripe::APIConnectionError => e
          process_error(e, args)
        rescue Stripe::StripeError => e
          process_error(e, args)
        rescue StandardError => e
          process_error(e, args)
        end
      end

      private

      def normalize_card_attributes(result)
        {
          card_brand:     result.brand.to_s,
          card_exp_month: result.exp_month.to_s,
          card_exp_year:  result.exp_year.to_s,
          card_last4:     result.last4.to_s,
          card_id:        result.id.to_s,
          client_id:      result.customer.to_s
        }
      end

      def normalize_token_attributes(result, client_id)
        {
          card_brand:     result.card.brand.to_s,
          card_exp_month: result.card.exp_month.to_s,
          card_exp_year:  result.card.exp_year.to_s,
          card_last4:     result.card.last4.to_s,
          card_id:        result.card.id.to_s,
          client_id:      client_id.to_s
        }
      end

      def normalize_card_model(result, client_id = '')
        @faraday_result = result

        if result.is_a?(Stripe::Token)
          @result  = normalize_id_attributes(result, client_id)
          @success = @result[:card_id].present?
        elsif result.is_a?(Stripe::Card)
          @result  = normalize_card_attributes(result)
          @success = @result[:card_id].present?
        # elsif result.is_a?(Stripe::ListObject)
        #   @success = true
        #   @result  = result.data.map do |item|
        #     normalize_card_attributes(item)
        #   end
        else
          @result = result
        end

        @result
      end
      # example response Stripe::Token (returned when card_token is a token)
      # {
      #   id:        'tok_1Pn1hHEo1z7FTBnw9vUfCGng',
      #   object:    'token',
      #   card:      {
      #     id: 'card_1Pn1hGEo1z7FTBnwqCI6ZVFp',
      #     object: 'card',
      #     address_city: null,
      #     address_country: null,
      #     address_line1: null,
      #     address_line1_check: null,
      #     address_line2: null,
      #     address_state: null,
      #     address_zip: null,
      #     address_zip_check: null,
      #     brand: 'Visa',
      #     country: 'US',
      #     cvc_check: 'pass',
      #     dynamic_last4: null,
      #     exp_month: 8,
      #     exp_year: 2030,
      #     fingerprint: 'B0kN2ueItnkL9wQR',
      #     funding: 'credit',
      #     last4: '4242',
      #     metadata: {},
      #     name: null,
      #     networks: { preferred: null },
      #     tokenization_method: null,
      #     wallet: null
      #   },
      #   client_ip: '76.223.227.145',
      #   created:   1_723_482_379,
      #   livemode:  false,
      #   type:      'card',
      #   used:      true
      # }
      # example response Stripe::Card (returned when card_token is a card)
      # {
      #   id:                  'card_1Pn1hGEo1z7FTBnwqCI6ZVFp',
      #   object:              'card',
      #   address_city:        null,
      #   address_country:     null,
      #   address_line1:       null,
      #   address_line1_check: null,
      #   address_line2:       null,
      #   address_state:       null,
      #   address_zip:         null,
      #   address_zip_check:   null,
      #   brand:               'Visa',
      #   country:             'US',
      #   customer:            'cus_EHTmI2oykEBvgw',
      #   cvc_check:           'pass',
      #   dynamic_last4:       null,
      #   exp_month:           8,
      #   exp_year:            2030,
      #   fingerprint:         'B0kN2ueItnkL9wQR',
      #   funding:             'credit',
      #   last4:               '4242',
      #   metadata:            {},
      #   name:                null,
      #   tokenization_method: null,
      #   wallet:              null
      # }
    end
  end
end
