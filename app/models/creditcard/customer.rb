# frozen_string_literal: true

# app/models/creditcard/customer.rb
module Creditcard
  class Customer < Creditcard::Base
    attribute :balance, :decimal
    attribute :card_id, :string
    attribute :client_id, :string
    attribute :created_at, :datetime
    attribute :delinquent, :boolean
    attribute :description, :string
    attribute :email, :string
    attribute :metadata, :string, default: -> { {}.to_json }
    attribute :name, :string
    attribute :phone, :string

    validates :balance, :card_id, :client_id, :created_at, :description, :name, presence: true

    # create a customer from a single use token
    # customer = Creditcard::Customer.create()
    #   (req) card_id:          (String)
    #   (req) name:             (String)
    #
    #   (opt) cust_description: (String)
    #   (opt) email:            (String)
    def self.create(**args)
      cc_client.customer_create(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        new_customer = new_attributes_from_result(**args)
        new_customer.errors.add(:customer, cc_client.message)

        new_customer
      end
    end

    # delete a customer with a customer token
    # customer.delete()
    def delete(**args)
      args[:client_id] = self.client_id
      @cc_client.customer_delete(**args)

      if @cc_client.success? && @cc_client.result.dig(:deleted)
        true
      else
        self.errors.add(:customer, @cc_client.message)

        false
      end
    end

    # retrieve a customer with a customer token
    # customer = Creditcard::Customer.find_by()
    #   (req) client_id: (String)
    def self.find_by(**args)
      cc_client.customer(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        nil
      end
    end

    # update a customer with a customer token
    # customer.update()
    #   (opt) card_id:          (String)
    #   (opt) cust_description: (String)
    #   (opt) email:            (String)
    #   (opt) name:             (String)
    def update(**args)
      args[:client_id] = self.client_id
      @cc_client.customer_update(**args)

      if @cc_client.success?
        update_attributes_from_result(@cc_client.result)
      else
        self.errors.add(:customer, @cc_client.message)

        false
      end
    end

    # retrieve a list of customers
    # customers = Creditcard::Customer.where()
    def self.where(**args)
      cc_client.customers

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
        balance:     result.dig(:balance),
        card_id:     result.dig(:card_id),
        client_id:   result.dig(:client_id),
        created_at:  result.dig(:created_at),
        delinquent:  result.dig(:delinquent).to_bool,
        description: result.dig(:description),
        email:       result.dig(:email),
        metadata:    result.dig(:metadata).presence || {},
        name:        result.dig(:name),
        phone:       result.dig(:phone)
      )
    end

    def update_attributes_from_result(result)
      self.balance     = result.dig(:balance)
      self.card_id     = result.dig(:card_id)
      self.client_id   = result.dig(:client_id)
      self.created_at  = result.dig(:created_at)
      self.delinquent  = result.dig(:delinquent).to_bool
      self.description = result.dig(:description)
      self.email       = result.dig(:email)
      self.metadata    = result.dig(:metadata).presence || {}
      self.name        = result.dig(:name)
      self.phone       = result.dig(:phone)

      true
    end
  end
end
