# frozen_string_literal: true

# app/models/creditcard/card.rb
module Creditcard
  class Card < Creditcard::Base
    attribute :card_brand, :string
    attribute :card_exp_month, :string
    attribute :card_exp_year, :string
    attribute :card_last4, :string
    attribute :card_id, :string
    attribute :client_id, :string

    validates :card_brand, :card_exp_month, :card_exp_year, :card_last4, :card_id, :client_id, presence: true

    # retrieve credit card info from single use token
    # card = Creditcard::Card.find_by()
    #   (req) card_id:   (String)
    #   (req) client_id: (String)
    def self.find_by(**args)
      cc_client.card(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        nil
      end
    end

    private

    def self.new_attributes_from_result(result)
      self.new(
        card_brand:     result.dig(:card_brand).to_s,
        card_exp_month: result.dig(:card_exp_month).to_s,
        card_exp_year:  result.dig(:card_exp_year).to_s,
        card_last4:     result.dig(:card_last4).to_s,
        card_id:        result.dig(:card_id).to_s,
        client_id:      result.dig(:client_id).to_s
      )
    end

    def update_attributes_from_result(result)
      self.card_brand     = result.dig(:card_brand).to_s
      self.card_exp_month = result.dig(:card_exp_month).to_s
      self.card_exp_year  = result.dig(:card_exp_year).to_s
      self.card_last4     = result.dig(:card_last4).to_s
      self.card_id        = result.dig(:card_id).to_s
      self.client_id      = result.dig(:client_id).to_s

      true
    end
  end
end
