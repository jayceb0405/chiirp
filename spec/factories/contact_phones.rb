# frozen_string_literal: true

FactoryBot.define do
  factory :contact_phone do
    contact

    phone   { '9123450098' }
    label   { 'Mobile' }
    primary { true }
  end
end
