# frozen_string_literal: true

# app/lib/credit_card/base.rb
module CreditCard
  class Base
    attr_accessor :error, :faraday_result, :message, :result, :success
    alias success? success

    # initialize CreditCard
    # cc_client = CreditCard::Base.new
    def initialize
      reset_attributes

      @cc_client = case credit_card_processor
                   when 'stripe'
                     CreditCard::StripeApi::Base.new
                   when 'authorizenet'
                     CreditCard::AuthorizeApi.new
                   else
                     nil
                   end
    end

    # get credit card info from single use token
    # result = CreditCard::Base.new.card()
    #   (req) card_id:   (String)
    #   (req) client_id: (String)
    def card(**args)
      reset_attributes

      @cc_client.card(**args)

      update_attributes
    end

    # charge a credit card
    # result = CreditCard::Base.new.charge_card()
    #   (req) amount:    (Decimal)
    #   (req) client_id: (String)
    #
    #   (opt) description:  (String)
    def charge_card(**args)
      reset_attributes

      @cc_client.charge_card(**args)

      update_attributes
    end

    # return the credit card processor used for this client
    def credit_card_processor
      Rails.application.credentials[:creditcard][:processor]
    end

    # retrieve a customer with a customer token
    # result = CreditCard::Base.new.customer()
    #   (req) client_id: (String)
    def customer(**args)
      reset_attributes

      @cc_client.customer(**args)

      update_attributes
    end

    # create a customer from a single use token
    # result = CreditCard::Base.new.customer_create()
    #   (req) card_id:          (String)
    #   (req) name:             (String)
    #
    #   (opt) cust_description: (String)
    #   (opt) email:            (String)
    def customer_create(**args)
      reset_attributes

      @cc_client.customer_create(**args)

      update_attributes
    end

    # delete a customer with a customer token
    # result = CreditCard::Base.new.customer_delete()
    #   (req) client_id: (String)
    def customer_delete(**args)
      reset_attributes

      @cc_client.customer_delete(**args)

      update_attributes
    end

    # update a customer with a customer token
    # result = CreditCard::Base.new.customer_update()
    #   (req) client_id:        (String)
    #
    #   (opt) card_id:          (String)
    #   (opt) cust_description: (String)
    #   (opt) email:            (String)
    #   (opt) name:             (String)
    def customer_update(**args)
      reset_attributes

      @cc_client.customer_update(**args)

      update_attributes
    end

    # list customers
    # result = CreditCard::Base.new.customers
    def customers
      reset_attributes

      @cc_client.customers

      update_attributes
    end

    # retrieve a price
    # result = CreditCard::Base.new.price()
    #   (req) price_id: (String)
    def price(**args)
      reset_attributes

      @cc_client.price(**args)

      update_attributes
    end

    # create a price
    # result = CreditCard::Base.new.price_create()
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

      @cc_client.price_create(**args)

      update_attributes
    end

    # update a Stripe::Price
    # result = CreditCard::Base.new.price_update()
    #   (req) price_id:       (String)
    #
    #   (opt) active:         (Boolean)
    #   (opt) metadata:       (Hash / default: {})
    #   (opt) name:           (String)
    def price_update(**args)
      reset_attributes

      @cc_client.price_update(**args)

      update_attributes
    end

    # list prices
    # result = CreditCard::Base.new.prices
    #   (req) product_id: (String)
    #
    #   (opt) active:     (Boolean)
    def prices(**args)
      reset_attributes

      @cc_client.prices(**args)

      update_attributes
    end

    # retrieve a product
    # result = CreditCard::Base.new.product()
    #   (req) product_id: (String)
    def product(**args)
      reset_attributes

      @cc_client.product(**args)

      update_attributes
    end

    # create a product
    # result = CreditCard::Base.new.product_create()
    #   (req) name: (String)
    #
    #   (opt) metadata: (Hash)
    def product_create(**args)
      reset_attributes

      @cc_client.product_create(**args)

      update_attributes
    end

    # delete a product
    # result = CreditCard::Base.new.product_delete()
    #   (req) product_id: (String)
    def product_delete(**args)
      reset_attributes

      @cc_client.product_delete(**args)

      update_attributes
    end

    # update a product
    # result = CreditCard::Base.new.product_update()
    #   (req) product_id: (String)
    #
    #   (opt) metadata:   (Hash)
    #   (opt) name:       (String)
    def product_update(**args)
      reset_attributes

      @cc_client.product_update(**args)

      update_attributes
    end

    # list products
    # result = CreditCard::Base.new.products
    #   (opt) active: (Boolean)
    def products(**args)
      reset_attributes

      @cc_client.products(**args)

      update_attributes
    end

    # return the stripe public key used for this client
    # CreditCard::Base.new.stripe_credit_card_pub_key
    def stripe_credit_card_pub_key
      Rails.application.credentials[:creditcard][:stripe][:pub_key]
    end

    # list Subscription Schedules for a customer
    # result = CreditCard::Base.new.subscription_schedules()
    #   (req) client_id: (String)
    def subscription_schedules(**args)
      reset_attributes

      @cc_client.subscription_schedules(**args)

      update_attributes
    end

    # create a new Subscription Schedule for a customer
    # result = CreditCard::SubscriptionSchedules.subscription_schedule_create()
    #   (req) client_id:    (String)
    #   (req) phases:       (Array of Hashes)
    #     (req) description:  (String)
    #     (opt) end_at:       (DateTime)
    #     (req) items:        (Array)
    #     (opt) trial_end_at: (DateTime)
    #   (req) start_at:     (DateTime)
    def subscription_schedule_create(**args)
      reset_attributes

      @cc_client.subscription_schedule_create(**args)

      update_attributes
    end

    private

    def reset_attributes
      @error          = 0
      @faraday_result = nil
      @message        = ''
      @result         = nil
      @success        = false
    end

    def update_attributes
      @error          = @cc_client.error
      @faraday_result = @cc_client.faraday_result
      @message        = @cc_client.message
      @result         = @cc_client.result
      @success        = @cc_client.success?

      @result
    end
  end
end
