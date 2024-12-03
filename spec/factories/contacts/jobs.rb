# frozen_string_literal: true

FactoryBot.define do
  factory :job, class: 'Contacts::Job' do
    contact

    total_amount { 10.99 }
    outstanding_balance { 10.99 }
    ext_invoice_id { 'asdf101' }
  end
end
