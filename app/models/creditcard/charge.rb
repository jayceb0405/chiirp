# frozen_string_literal: true

# app/models/creditcard/charge.rb
module Creditcard
  class Charge < Creditcard::Base
    attribute :amount, :decimal
    attribute :amount_captured, :decimal
    attribute :card_id, :string
    attribute :client_id, :string
    attribute :description, :string
    attribute :message, :string
    attribute :status, :string
    attribute :trans_id, :string

    validates :amount, :amount_captured, :card_id, :client_id, :description, :message, :status, :trans_id, presence: true

    # charge a credit card
    # charge = Creditcard::Charge.create()
    #   (req) amount:       (Decimal)
    #   (req) client_id:    (String)
    #
    #   (opt) description:  (String)
    def self.create(**args)
      cc_client.charge_card(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        new_charge = new_attributes_from_result(**args)
        new_charge.errors.add(:charge, cc_client.message)

        new_charge
      end
    end

    private

    def self.new_attributes_from_result(result)
      self.new(
        amount:          result.dig(:amount),
        amount_captured: result.dig(:amount_captured),
        card_id:         result.dig(:card_id),
        client_id:       result.dig(:client_id),
        description:     result.dig(:description),
        message:         result.dig(:message),
        status:          result.dig(:status),
        trans_id:        result.dig(:trans_id)
      )
    end

    def update_attributes_from_result(result)
      self.amount          = result.dig(:amount)
      self.amount_captured = result.dig(:amount_captured)
      self.card_id         = result.dig(:card_id)
      self.client_id       = result.dig(:client_id)
      self.description     = result.dig(:description)
      self.message         = result.dig(:message)
      self.status          = result.dig(:status)
      self.trans_id        = result.dig(:trans_id)

      true
    end
  end
end
