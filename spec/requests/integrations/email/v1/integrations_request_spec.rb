# frozen_string_literal: true

require 'rails_helper'

# foreman run bundle exec rspec spec/requests/integrations/email/integrations_request_spec.rb
RSpec.describe Integrations::Email::V1::IntegrationsController, type: :request do
  let(:client) { create :client }
  let(:client_api_integration) { create :client_api_integration_for_email, client: }
  let(:params_email) do
    {
      token:    Rails.application.credentials.dig(:email, :sendgrid_inbound_token),
      headers:  <<~HEADERS,
        From: Tester Joe <joe@tester.com>
      HEADERS
      text:     'Hello, world!',
      html:     '<p>Hello, world!</p>',
      envelope: {
        to:   [client_api_integration.inbound_username],
        from: 'joe@tester.com'
      }.to_json
    }
  end
  let(:params_email_bad_encoding) do
    params = params_email
    params[:text] += "\xe1"
    params[:html] += "\xe1"
    params
  end

  describe 'POST /integrations/email/v1/inbound' do
    it 'returns success' do
      post integrations_email_v1_inbound_path, params: params_email
      expect(response).to have_http_status(:success)
    end

    it 'allows malformed utf-8 characters' do
      post integrations_email_v1_inbound_path, params: params_email_bad_encoding
      expect(response).to have_http_status(:success)
    end
  end
end
