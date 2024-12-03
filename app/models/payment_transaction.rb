# frozen_string_literal: true

# app/models/payment_transaction.rb
# PaymentTransaction.new
class PaymentTransaction < ApplicationRecord
  belongs_to :client, optional: true
  belongs_to :contact_job, optional: true
end
