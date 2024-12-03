# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token, class: 'Doorkeeper::AccessToken' do
    resource_owner_id { create(:user).id }
    application_id { create(:oauth_application).id }
    # presetting the tokens does not work; Doorkeeper will overwrite them
    # token { SecureRandom.alphanumeric(34) }
    # refresh_token { SecureRandom.alphanumeric(34) }
    scopes { 'write' }
    expires_in { 2.hours }
  end
end
