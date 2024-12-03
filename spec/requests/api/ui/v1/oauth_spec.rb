# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Oauth', type: :request do
  let(:token) { access_token.instance_variable_get(:@raw_token) }
  let(:access_token) { create(:oauth_access_token) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    sign_in User.find(access_token.resource_owner_id)
  end

  describe 'with valid access token' do
    it 'returns http success' do
      get(me_api_ui_v1_users_path(format: :json), headers:)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'with revoked access token' do
    before do
      access_token.revoke
    end

    it 'returns http unauthorized' do
      get(me_api_ui_v1_users_path(format: :json), headers:)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
