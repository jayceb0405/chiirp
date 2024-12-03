# frozen_string_literal: true

# app/models/creditcard/base.rb
module Creditcard
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::AttributeAssignment
    include ActiveModel::Validations

    # initialize CreditCard
    # xxx = Creditcard::Xxx.new
    def initialize(**args)
      super

      @cc_client = CreditCard::Base.new
    end

    def self.cc_client
      @cc_client ||= CreditCard::Base.new
    end

    # return the stripe public key used for this client
    def self.stripe_credit_card_pub_key
      cc_client.stripe_credit_card_pub_key
    end

    # return the credit card processor used for this model
    def self.credit_card_processor
      cc_client.credit_card_processor
    end
  end
end
