# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: 'Doorkeeper::Application' do
    name { 'Test' }
    uid { SecureRandom.uuid }
    secret { SecureRandom.alphanumeric(32) }
    confidential { false }
    scopes { 'write' }
    redirect_uri { 'https://localhost/' }
  end
end
