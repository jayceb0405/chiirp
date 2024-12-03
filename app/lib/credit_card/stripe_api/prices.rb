# frozen_string_literal: true

# app/lib/credit_card/stripe_api/prices.rb
module CreditCard
  module StripeApi
    module Prices
      # retrieve a Stripe::Price
      # result = CreditCard::StripeApi::Base.new.price()
      #   (req) price_id: (String)
      def price(**args)
        reset_attributes

        if args.dig(:price_id).to_s.empty?
          @result  = {}
          @message = 'Price token is required'
          return @result
        end

        begin
          normalize_price_model(Stripe::Price.retrieve(args[:price_id].to_s))
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

      # create a Stripe::Price
      # result = CreditCard::StripeApi::Base.new.price_create()
      #   (req) name:           (String)
      #   (req) product_id:     (String)
      #
      #   (opt) billing_scheme: (String / default: per_unit) ex: per_unit, tiered
      #   (opt) metadata:       (Hash / default: {})
      #   (opt) price:          (BigDecimal / default: 0.00)
      #   (opt) recurring:      (Hash)
      #     (opt) interval:          (String / default: month) ex: day, week, month, year
      #     (opt) interval_count:    (Integer / default: 1)
      #     (opt) trial_period_days: (Integer / default: 0)
      def price_create(**args)
        reset_attributes

        if args.dig(:name).to_s.empty?
          @result  = {}
          @message = 'Product name is required'
          return @result
        elsif args.dig(:product_id).to_s.empty?
          @result  = {}
          @message = 'Product token is required'
          return @result
        end

        begin
          normalize_price_model(Stripe::Price.create({
                                                       billing_scheme: %w[per_unit tiered].include?(args.dig(:billing_unit).to_s.downcase) ? args[:billing_unit].to_s.downcase : 'per_unit',
                                                       currency:       'usd',
                                                       metadata:       args.dig(:metadata).presence || {},
                                                       nickname:       args[:name].to_s,
                                                       product:        args[:product_id].to_s,
                                                       recurring:      {
                                                         interval:          %w[day week month year].include?(args.dig(:recurring, :interval).to_s.downcase) ? args.dig(:recurring, :interval).to_s.downcase : 'month',
                                                         interval_count:    [1, args.dig(:recurring, :interval_count).to_i].max,
                                                         trial_period_days: args.dig(:recurring, :trial_period_days).to_i
                                                       },
                                                       unit_amount:    ((args.dig(:price).presence || 0).to_d * 100).to_i # must be integer in cents
                                                     }))
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

      # update a Stripe::Price
      # result = CreditCard::StripeApi::Base.new.price_update()
      #   (req) price_id:       (String)
      #
      #   (opt) active:         (Boolean)
      #   (opt) metadata:       (Hash / default: {})
      #   (opt) name:           (String)
      def price_update(**args)
        reset_attributes

        if args.dig(:price_id).to_s.empty?
          @result  = {}
          @message = 'Price token is required'
          return @result
        end

        begin
          price = {}
          price[:active]                        = args[:active] unless args.dig(:active).nil?
          price[:metadata]                      = args[:metadata] if args.dig(:metadata).present?
          price[:nickname]                      = args[:name].to_s if args.dig(:name).present?
          normalize_price_model(Stripe::Price.update(args[:price_id].to_s, **price))
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

      # list Stripe::Prices
      # result = CreditCard::StripeApi::Base.new.prices
      #   (req) product_id: (String)
      #
      #   (opt) active:     (Boolean)
      def prices(**args)
        reset_attributes

        if args.dig(:product_id).to_s.empty?
          @result  = {}
          @message = 'Product token is required'
          return @result
        end

        begin
          data             = []
          params           = {
            limit:   100,
            product: args[:product_id].to_s
          }
          params[:active]  = args[:active] unless args.dig(:active).nil?
          result           = {}
          starting_after   = nil

          loop do
            params[:starting_after] = starting_after if starting_after.present?

            result = Stripe::Price.list(**params)

            data += result.data

            break unless result.has_more

            starting_after = result.starting_after
          end

          result.data = data

          normalize_price_model(result)
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

      def normalize_price_attributes(result)
        {
          active:         result.active.present?,
          billing_scheme: result.billing_scheme.to_s,
          created_at:     Time.at(result.created.to_i),
          currency:       result.currency.to_s,
          metadata:       JSON.parse(result.metadata.to_json, symbolize_names: true),
          name:           result.nickname.to_s,
          price_id:       result.id.to_s,
          product_id:     result.product.to_s,
          recurring:      {
            interval:          result.respond_to?(:recurring) && result.recurring.respond_to?(:interval) ? result.recurring.interval.to_s : '',
            interval_count:    result.respond_to?(:recurring) && result.recurring.respond_to?(:interval_count) ? result.recurring.interval_count.to_i : 0,
            trial_period_days: result.respond_to?(:recurring) && result.recurring.respond_to?(:trial_period_days) ? result.recurring.trial_period_days.to_i : 0
          },
          price:          result.unit_amount.to_i / 100.0,
          type:           result.type.to_s
        }
      end

      def normalize_price_model(result)
        @faraday_result = result

        if result.is_a?(Stripe::Price)
          @success = true
          @result  = normalize_price_attributes(result)
        elsif result.is_a?(Stripe::ListObject)
          @success = true
          @result  = result.data.map do |item|
            normalize_price_attributes(item)
          end
        else
          @result = result
        end
      end
      # example Stripe::Price model
      # {
      #   id:                  'price_1Po912Eo1z7FTBnwVtgPPB0Q',
      #   object:              'price',
      #   active:              true,
      #   billing_scheme:      'per_unit',
      #   created:             1723748840,
      #   currency:            'usd',
      #   custom_unit_amount:  null,
      #   livemode:            false,
      #   lookup_key:          null,
      #   metadata:            {},
      #   nickname:            'Super User / Gold',
      #   product:             'prod_QfTztHaeQErgio',
      #   recurring:           { aggregate_usage: null, interval: 'month', interval_count: 1, meter: null, trial_period_days: null, usage_type: 'licensed' },
      #   tax_behavior:        'unspecified',
      #   tiers_mode:          null,
      #   transform_quantity:  null,
      #   type:                'recurring',
      #   unit_amount:         10000,
      #   unit_amount_decimal: '10000'
      # }
      # example Stripe::ListObject for Stripe::Prices
      # {
      #   object:   'list',
      #   data:     [
      #     {
      #       id:                  'plan_DslkSy2jmvpDtu',
      #       object:              'price',
      #       active:              true,
      #       billing_scheme:      'per_unit',
      #       created:             1540917381,
      #       currency:            'usd',
      #       custom_unit_amount:  null,
      #       livemode:            false,
      #       lookup_key:          null,
      #       metadata:            {},
      #       nickname:            'TexttStandard',
      #       product:             'prod_DslFzoabBZZpV5',
      #       recurring:           { aggregate_usage: null, interval: 'month', interval_count: 1, meter: null, trial_period_days: null, usage_type: 'licensed' },
      #       tax_behavior:        'unspecified',
      #       tiers_mode:          null,
      #       transform_quantity:  null,
      #       type:                'recurring',
      #       unit_amount:         9900,
      #       unit_amount_decimal: '9900'
      #     }
      #   ],
      #   has_more: false,
      #   url:      '/v1/prices'
      # }
    end
  end
end
