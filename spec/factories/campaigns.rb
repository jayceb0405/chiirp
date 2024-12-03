# frozen_string_literal: true

FactoryBot.define do
  factory :campaign do
    client
    name         { 'Testing' }
    allow_repeat { false }

    factory :campaign_with_trigger_and_action do
      after(:create) do |campaign, _evaluator|
        create_list(:trigger, 1, campaign:)
        create_list(:triggeraction, 1, trigger: campaign.reload.triggers.first)
      end
    end
  end
end
