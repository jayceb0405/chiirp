# frozen_string_literal: true

# app/lib/credit_card/stripe_api/products.rb
module CreditCard
  module StripeApi
    module Products
      # retrieve a Stripe::Product
      # result = CreditCard::StripeApi::Base.new.product()
      #   (req) product_id: (String)
      def product(**args)
        reset_attributes

        if args.dig(:product_id).to_s.empty?
          @result  = {}
          @message = 'Product token is required'
          return @result
        end

        begin
          normalize_product_model(Stripe::Product.retrieve(args[:product_id].to_s))
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

      # create a Stripe::Product
      # result = CreditCard::StripeApi::Base.new.product_create()
      #   (req) name:        (String)
      #
      #   (opt) active:      (Boolean)
      #   (opt) description: (String)
      #   (opt) metadata:    (Hash)
      def product_create(**args)
        reset_attributes

        if args.dig(:name).to_s.empty?
          @result  = {}
          @message = 'Product name is required'
          return @result
        end

        begin
          product_data = {
            name: args[:name].to_s
          }
          product_data[:active]      = args[:active].to_bool unless args.dig(:active).nil?
          product_data[:description] = args[:description].to_s unless args.dig(:description).nil?
          product_data[:metadata]    = args[:metadata] unless args.dig(:metadata).nil?

          normalize_product_model(Stripe::Product.create(**product_data))
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

      # delete a Stripe::Product
      # result = CreditCard::StripeApi::Base.new.product_delete()
      #   (req) product_id: (String)
      def product_delete(**args)
        reset_attributes

        if args.dig(:product_id).to_s.empty?
          @result  = {}
          @message = 'Product token is required'
          return @result
        end

        begin
          normalize_product_model(Stripe::Product.delete(args[:product_id].to_s))
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

      # update a Stripe::Product
      # result = CreditCard::StripeApi::Base.new.product_update()
      #   (req) product_id:  (String)
      #
      #   (opt) active:      (Boolean)
      #   (opt) description: (String)
      #   (opt) metadata:    (Hash)
      #   (opt) name:        (String)
      def product_update(**args)
        reset_attributes

        if args.dig(:product_id).to_s.empty?
          @result  = {}
          @message = 'Product token is required'
          return @result
        end

        begin
          product_data = {}
          product_data[:active] = args[:active].to_bool unless args.dig(:active).nil?
          product_data[:description] = args[:description].to_s unless args.dig(:description).nil?
          product_data[:metadata]    = args[:metadata] unless args.dig(:metadata).nil?
          product_data[:name]        = args[:name].to_s unless args.dig(:name).nil?

          return product(**args) if product_data.empty?

          normalize_product_model(Stripe::Product.update(args[:product_id].to_s, **product_data))
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

      # list Stripe::Products
      # result = CreditCard::StripeApi::Base.new.products
      #   (opt) active: (Boolean)
      def products(**args)
        reset_attributes

        begin
          data            = []
          params          = {
            limit: 100
          }
          params[:active] = args[:active] unless args.dig(:active).nil?
          result          = {}
          starting_after  = nil

          loop do
            params[:starting_after] = starting_after if starting_after.present?

            result = Stripe::Product.list(**params)

            data += result.data

            break unless result.has_more

            starting_after = result.starting_after
          end

          result.data = data

          normalize_product_model(result)
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

      def normalize_product_attributes(result)
        {
          active:           result.active.present?,
          created_at:       Time.at(result.created.to_i),
          default_price_id: result.default_price.to_s,
          description:      result.description.to_s,
          metadata:         JSON.parse(result.metadata.to_json, symbolize_names: true),
          name:             result.name.to_s,
          product_id:       result.id.to_s,
          type:             result.type.to_s, # good, service
          updated_at:       Time.at(result.updated.to_i)
        }
      end

      def normalize_product_model(result)
        @faraday_result = result

        if result.is_a?(Stripe::Product)
          @success = true
          @result  = if result.respond_to?(:deleted)
                       { product_id: result.id.to_s, deleted: result.deleted }
                     else
                       normalize_product_attributes(result)
                     end
        elsif result.is_a?(Stripe::ListObject)
          @success = true
          @result  = result.data.map do |item|
            normalize_product_attributes(item)
          end
        else
          @result = result
        end
      end
      # example Stripe::Product model
      # {
      #   id:                 'prod_GzNW6yrmcX1s76',
      #   object:             'product',
      #   active:             true,
      #   attributes:         [
      #     'name'
      #   ],
      #   caption:            null,
      #   created:            1585340810,
      #   deactivate_on:      [],
      #   default_price:      null,
      #   description:        null,
      #   images:             [],
      #   livemode:           false,
      #   marketing_features: [],
      #   metadata:           { package: 'ZdYyhVwoFRhVbzsvY2M2', page: 'xrBUpVt1CIHtVlFSib26' },
      #   name:               'Funny Papers',
      #   package_dimensions: null,
      #   shippable:          true,
      #   tax_code:           null,
      #   type:               'good',
      #   updated:            1585341087,
      #   url:                null
      # }
      # example Stripe::ListObject for Stripe::Products
      # {
      #   object:   'list',
      #   data:     [
      #     {
      #       id:                 'prod_GzNW6yrmcX1s76',
      #       object:             'product',
      #       active:             true,
      #       attributes:         ['name'],
      #       caption:            null,
      #       created:            1585340810,
      #       deactivate_on:      [],
      #       default_price:      null,
      #       description:        null,
      #       images:             [],
      #       livemode:           false,
      #       marketing_features: [],
      #       metadata:           { package: 'ZdYyhVwoFRhVbzsvY2M2', page: 'xrBUpVt1CIHtVlFSib26' },
      #       name:               'Funny Papers',
      #       package_dimensions: null,
      #       shippable:          true,
      #       tax_code:           null,
      #       type:               'good',
      #       updated:            1585341087,
      #       url:                null
      #     },...
      #   ],
      #   has_more: false,
      #   url:      '/v1/products'
      # }
    end
  end
end
