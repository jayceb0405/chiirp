# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    client
    user

    firstname { 'Joe' }
    lastname { 'Tester' }

    factory :contact_with_email do
      sequence(:email) { |n| "contact#{n}@chiirp.com" }
    end

    factory :contact_with_companynmame do
      companyname { 'ACME, Inc.' }
    end
  end
end
