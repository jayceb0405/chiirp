# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    name       { 'Testing with Joe' }
    address1   { 'PO Box 123' }
    city       { 'Ducktown' }
    state      { 'TN' }
    zip        { '37317' }
    phone      { '4235551212' }
    time_zone  { 'Eastern Time (US & Canada)' }

    campaigns_count      { 100 }
    integrations_allowed { %w[callrail testing] }

    terms_accepted { Time.now.utc }

    max_email_templates { 10 }
    trackable_links_count { 10 }

    def_user { association :user, client: instance }
    after(:create) { |client| client.def_user.save }
  end
end
