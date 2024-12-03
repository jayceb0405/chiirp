# frozen_string_literal: true

# app/lib/credit_card/stripe_api/customers.rb
module CreditCard
  module StripeApi
    module Customers
      # retrieve a Stripe::Customer
      # result = CreditCard::StripeApi::Base.new.customer()
      #   (req) client_id: (String)
      def customer(**args)
        reset_attributes

        if args.dig(:client_id).to_s.empty?
          @result  = {}
          @message = 'Client token is required'
          return @result
        end

        begin
          normalize_customer_model(Stripe::Customer.retrieve(args[:client_id].to_s))
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

      # create a Stripe::Customer
      # result = CreditCard::StripeApi::Base.new.customer_create()
      #   (req) card_id:          (String)
      #   (req) name:             (String)
      #
      #   (opt) cust_description: (String)
      #   (opt) email:            (String)
      def customer_create(**args)
        reset_attributes

        if args.dig(:card_id).to_s.empty?
          @result  = {}
          @message = 'Card token is required'
          return @result
        elsif args.dig(:name).to_s.empty?
          @result  = {}
          @message = 'Customer name is required'
          return @result
        end

        begin
          normalize_customer_model(Stripe::Customer.create(
                                     description: args.dig(:cust_description).to_s,
                                     email:       args.dig(:email).to_s,
                                     name:        args[:name].to_s,
                                     source:      args[:card_id].to_s
                                   ))
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

      # delete a Stripe::Customer
      # result = CreditCard::StripeApi::Base.new.customer_delete()
      #   (req) client_id: (String)
      def customer_delete(**args)
        reset_attributes

        if args.dig(:client_id).to_s.empty?
          @result  = {}
          @message = 'Client token is required'
          return @result
        end

        begin
          normalize_customer_model(Stripe::Customer.delete(args[:client_id].to_s))
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

      # update a Stripe::Customer
      # result = CreditCard::StripeApi::Base.new.customer_update()
      #   (req) client_id:        (String)
      #
      #   (opt) card_id:          (String)
      #   (opt) cust_description: (String)
      #   (opt) email:            (String)
      #   (opt) name:             (String)
      def customer_update(**args)
        reset_attributes

        if args.dig(:client_id).to_s.empty?
          @result  = {}
          @message = 'Client token is required'
          return @result
        end

        begin
          client_data = {}
          client_data[:description] = args[:cust_description].to_s unless args.dig(:cust_description).to_s.empty?
          client_data[:source]      = args[:card_id].to_s unless args.dig(:card_id).to_s.empty?
          client_data[:email]       = args[:email].to_s unless args.dig(:email).to_s.empty?
          client_data[:name]        = args[:name].to_s unless args.dig(:name).to_s.empty?

          normalize_customer_model(Stripe::Customer.update(args[:client_id].to_s, client_data))
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

      # list Stripe::Customers
      # result = CreditCard::StripeApi::Base.new.customers
      def customers
        reset_attributes

        begin
          data = []
          result         = {}
          starting_after = nil

          loop do
            params = {
              limit: 10
            }
            params[:starting_after] = starting_after if starting_after.present?

            result = Stripe::Customer.list(**params)

            data += result.data

            break unless result.has_more

            # starting_after = result.starting_after
            starting_after = result.data.last.id
          end

          result.data = data

          normalize_customer_model(result)
        rescue Stripe::CardError => e
          process_error(e, args)
        rescue Stripe::RateLimitError => e
          process_error(e, {})
        rescue Stripe::InvalidRequestError => e
          process_error(e, {})
        rescue Stripe::AuthenticationError => e
          process_error(e, {})
        rescue Stripe::APIConnectionError => e
          process_error(e, {})
        rescue Stripe::StripeError => e
          process_error(e, {})
        rescue StandardError => e
          process_error(e, {})
        end
      end

      private

      def normalize_customer_attributes(result)
        {
          balance:     result.balance.to_i / 100.0,
          card_id:     result.default_source.to_s,
          client_id:   result.id.to_s,
          created_at:  Time.at(result.created.to_i),
          delinquent:  result.delinquent,
          description: result.description.to_s,
          email:       result.email.to_s,
          metadata:    JSON.parse(result.metadata.to_json, symbolize_names: true),
          name:        result.name.to_s,
          phone:       result.phone.to_s
        }
      end

      def normalize_customer_model(result)
        @faraday_result = result

        if result.is_a?(Stripe::Customer)
          @success = true
          @result  = if result.respond_to?(:deleted)
                       { client_id: result.id.to_s, deleted: result.deleted }
                     else
                       normalize_customer_attributes(result)
                     end
        elsif result.is_a?(Stripe::ListObject)
          @success = true
          @result  = result.data.map do |price|
            normalize_customer_attributes(price)
          end
        else
          @result = result
        end
      end
      # example Stripe::Customer response when deleted
      # {
      #   "id": "cus_EK6xRQGQcNwJJ1",
      #   "object": "customer",
      #   "deleted": true
      # }
      # example Stripe::Customer response
      # {
      #   id:                    'cus_EHTmI2oykEBvgw',
      #   object:                'customer',
      #   address:               null,
      #   balance:               0,
      #   created:               1546616590,
      #   currency:              null,
      #   default_source:        'card_1Pn1hGEo1z7FTBnwqCI6ZVFp',
      #   delinquent:            false,
      #   description:           "Joe's Garage (8023455136)",
      #   discount:              null,
      #   email:                 'kevin@kevinneubert.com',
      #   invoice_prefix:        '2470ADE',
      #   invoice_settings:      { custom_fields: null, default_payment_method: null, footer: null, rendering_options: null },
      #   livemode:              false,
      #   metadata:              {},
      #   name:                  "Joe's Garage",
      #   next_invoice_sequence: 1,
      #   phone:                 null,
      #   preferred_locales:     [],
      #   shipping:              null,
      #   tax_exempt:            'none',
      #   test_clock:            null
      # }
      # example Stripe::ListObject of Stripe::Customers
      # {
      #   object:   'list',
      #   data:     [
      #     {
      #       id:                    'cus_EHTmI2oykEBvgw',
      #       object:                'customer',
      #       address:               null,
      #       balance:               0,
      #       created:               1546616590,
      #       currency:              null,
      #       default_source:        'card_1Pn1hGEo1z7FTBnwqCI6ZVFp',
      #       delinquent:            false,
      #       description:           "Joe's Garage (8023455136)",
      #       discount:              null,
      #       email:                 'kevin@kevinneubert.com',
      #       invoice_prefix:        '2470ADE',
      #       invoice_settings:      { custom_fields: null, default_payment_method: null, footer: null, rendering_options: null },
      #       livemode:              false,
      #       metadata:              {},
      #       name:                  "Joe's Garage",
      #       next_invoice_sequence: 1,
      #       phone:                 null,
      #       preferred_locales:     [],
      #       shipping:              null,
      #       tax_exempt:            'none',
      #       test_clock:            null
      #     }
      #   ],
      #   has_more: false,
      #   url:      '/v1/customers'
      # }
    end
  end
end
