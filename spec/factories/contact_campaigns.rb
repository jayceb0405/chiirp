# frozen_string_literal: true

FactoryBot.define do
  factory :contact_campaign, class: 'Contacts::Campaign' do
    contact
    campaign
  end
end
