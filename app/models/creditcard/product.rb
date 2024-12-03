# frozen_string_literal: true

# app/models/creditcard/product.rb
module Creditcard
  class Product < Creditcard::Base
    attribute :active, :boolean, default: true
    attribute :created_at, :datetime
    attribute :default_price_id, :string
    attribute :description, :string
    attribute :metadata, :string, default: -> { {}.to_json }
    attribute :name, :string
    attribute :product_id, :string
    attribute :type, :string
    attribute :updated_at, :datetime

    validates :created_at, :default_price_id, :name, :product_id, :updated_at, presence: true

    # create a product
    # product = Creditcard::Product.create()
    #   (req) name:        (String)
    #
    #   (opt) active:      (Boolean)
    #   (opt) description: (String)
    #   (opt) metadata:    (Hash)
    def self.create(**args)
      cc_client.product_create(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        new_product = new_attributes_from_result(**args)
        new_product.errors.add(:product, cc_client.message)

        new_product
      end
    end

    # delete a product
    # product.delete
    def delete(**args)
      args[:product_id] = self.product_id
      @cc_client.product_delete(**args)

      if @cc_client.success? && @cc_client.result.dig(:deleted)
        true
      else
        self.errors.add(:product, @cc_client.message)

        false
      end
    end

    # retrieve a product
    # product = Creditcard::Product.find_by()
    #   (req) product_id: (String)
    def self.find_by(**args)
      cc_client.product(**args)

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

    # retrieve product for a Chiirp Package
    # package_product = Creditcard::Product.package_product()
    #   (req) sudo_name: (String) ex: setup_fee, promo_monthly_charge, monthly_ai_charge, monthly_charge
    def self.package_product(sudo_name)
      self.package_products.find { |p| p.metadata.dig(:sudo_name) == sudo_name.to_s } || {}
    end

    # retreive a product name
    # package_product_name = Creditcard::Product.package_product_name()
    #   (req) sudo_name: (String) ex: setup_fee, promo_monthly_charge, monthly_ai_charge, monthly_charge
    def self.package_product_name(sudo_name)
      self.package_product_names.dig(sudo_name.to_s.to_sym).to_s
    end

    # retreive product names
    # package_product_names = Creditcard::Product.package_product_names
    def self.package_product_names
      self.package_products.map { |p| [p.metadata.dig(:sudo_name), p.name] if p.metadata.dig(:sudo_name).present? }.compact_blank.to_h.symbolize_keys
    end
    # example package_product_names
    # {
    #   promo_monthly_charge: 'Promotional Monthly Charge',
    #   monthly_ai_charge:    'Monthly AI Charge',
    #   setup_fee:            'Setup Fee',
    #   monthly_charge:       'Monthly Charge'
    # }

    # retrieve products used for Chiirp Packages
    # package_products = Creditcard::Product.package_products
    def self.package_products
      @package_products ||= self.where(active: true).select { |p| p.metadata.dig(:package).to_bool }
    end

    # update a product
    # product.update()
    #   (opt) active:         (Boolean)
    #   (opt) description:    (String)
    #   (opt) metadata:       (Hash / default: {})
    #   (opt) name:           (String)
    def update(**args)
      args[:product_id] = self.product_id
      @cc_client.product_update(**args)

      if @cc_client.success?
        update_attributes_from_result(@cc_client.result)
      else
        self.errors.add(:product, @cc_client.message)

        false
      end
    end

    # list products
    # product = Creditcard::Product.where()
    #   (opt) active: (Boolean)
    def self.where(**args)
      cc_client.products(**args)

      if cc_client.success?
        response = []

        cc_client.result.each do |product|
          response << new_attributes_from_result(product)
        end

        response
      else
        []
      end
    end

    private

    def self.new_attributes_from_result(result)
      self.new(
        active:           result.dig(:active).to_bool,
        created_at:       result.dig(:created_at),
        default_price_id: result.dig(:default_price_id),
        description:      result.dig(:description),
        metadata:         result.dig(:metadata).presence || {},
        name:             result.dig(:name),
        product_id:       result.dig(:product_id),
        type:             result.dig(:type),
        updated_at:       result.dig(:updated_at)
      )
    end

    def update_attributes_from_result(result)
      self.active           = result.dig(:active).to_bool
      self.created_at       = result.dig(:created_at)
      self.default_price_id = result.dig(:default_price_id)
      self.description      = result.dig(:description)
      self.metadata         = result.dig(:metadata).presence || {}
      self.name             = result.dig(:name)
      self.description      = result.dig(:description)
      self.product_id       = result.dig(:product_id)
      self.type             = result.dig(:type)
      self.updated_at       = result.dig(:updated_at)

      true
    end
  end
end
