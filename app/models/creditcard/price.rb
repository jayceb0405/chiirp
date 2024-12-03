# frozen_string_literal: true

# app/models/creditcard/price.rb
module Creditcard
  class Price < Creditcard::Base
    attribute :active, :boolean, default: true
    attribute :billing_scheme, :string, default: 'per_unit'
    attribute :created_at, :datetime
    attribute :currency, :string, default: 'usd'
    attribute :metadata, :string, default: -> { {}.to_json }
    attribute :name, :string
    attribute :price, :decimal
    attribute :price_id, :string
    attribute :product_id, :string
    attribute :recurring, :string, default: -> { { interval: '', interval_count: 1, trial_period_days: 0 }.to_json }
    attribute :type, :string, default: 'recurring'

    validates :billing_scheme, :created_at, :currency, :name, :price, :price_id, :product_id, :type, presence: true

    # create a price
    # price = Creditcard::Price.create()
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
    def self.create(**args)
      cc_client.price_create(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        new_price = new_attributes_from_result(**args)
        new_price.errors.add(:price, cc_client.message)

        new_price
      end
    end

    # retrieve a price for a product
    # price = Creditcard::Price.find_by()
    #   (req) price_id: (String)
    def self.find_by(**args)
      cc_client.price(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        nil
      end
    end

    def metadata
      JSON.parse(self.attributes.dig('metadata')).symbolize_keys
    end

    def metadata=(value)
      _write_attribute('metadata', value.to_json)
    end

    def recurring
      JSON.parse(self.attributes.dig('recurring')).symbolize_keys
    end

    def recurring=(value)
      _write_attribute('recurring', value.to_json)
    end

    # update a price
    # price.update()
    #   (opt) active:         (Boolean)
    #   (opt) metadata:       (Hash / default: {})
    #   (opt) name:           (String)
    def update(**args)
      args[:price_id] = self.price_id
      @cc_client.price_update(**args)

      if @cc_client.success?
        update_attributes_from_result(@cc_client.result)
      else
        self.errors.add(:price, @cc_client.message)

        false
      end
    end

    # list prices for a product
    # price = Creditcard::Price.where()
    #   (req) product_id: (String)
    #   (opt) active:     (Boolean)
    def self.where(**args)
      cc_client.prices(**args)

      if cc_client.success?
        response = []

        cc_client.result.each do |price|
          response << new_attributes_from_result(price)
        end

        response
      else
        []
      end
    end

    private

    def self.new_attributes_from_result(result)
      self.new(
        active:         result.dig(:active).to_bool,
        billing_scheme: result.dig(:billing_scheme).presence || 'per_unit',
        created_at:     result.dig(:created_at),
        currency:       result.dig(:currency).presence || 'usd',
        metadata:       result.dig(:metadata) || {},
        name:           result.dig(:name),
        price:          result.dig(:price),
        price_id:       result.dig(:price_id),
        product_id:     result.dig(:product_id),
        recurring:      result.dig(:recurring) || {},
        type:           result.dig(:type).presence || 'recurring'
      )
    end

    def update_attributes_from_result(result)
      self.active         = result.dig(:active).to_bool
      self.billing_scheme = result.dig(:billing_scheme).presence || 'per_unit'
      self.created_at     = result.dig(:created_at)
      self.currency       = result.dig(:currency).presence || 'usd'
      self.metadata       = result.dig(:metadata) || {}
      self.name           = result.dig(:name)
      self.price          = result.dig(:price)
      self.price_id       = result.dig(:price_id)
      self.product_id     = result.dig(:product_id)
      self.recurring      = result.dig(:recurring) || {}
      self.type           = result.dig(:type).presence || 'recurring'

      true
    end
  end
end
