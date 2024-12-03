# frozen_string_literal: true

FactoryBot.define do
  sequence :email do |n|
    "test#{n}@chiirp.com"
  end

  factory :user do
    email
    password  { 'asdfasdf' }
    firstname { 'Joe' }
    lastname  { 'Tester' }

    client { association :client, def_user: instance }
  end
end
