# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrationsController, type: :request do
  let(:user) { create :user }
  let(:integration) { create :integration }

  before do
    # integration.logo_image.attach(io: Rails.root.join('spec/fixtures/files/logo.png').open, filename: 'logo.png', content_type: 'image/png')
    integration
    sign_in user
  end

  it 'returns http success' do
    get integrations_path
    expect(response).to have_http_status(:ok)
  end
end
