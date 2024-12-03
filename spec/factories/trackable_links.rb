# frozen_string_literal: true

FactoryBot.define do
  factory :trackable_link do
    client
    name { 'my trackable link' }
    original_url { 'https://www.apple.com' }

    tag_id { 0 }
    group_id { 0 }
    campaign_id { 0 }
  end
end
