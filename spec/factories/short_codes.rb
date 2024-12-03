# frozen_string_literal: true

FactoryBot.define do
  factory :short_code do
    client
    code { RandomCode.new.create(20) }
    url { 'https://app.chiirp.com/' }
  end
end
