# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SessionTimeout', type: :request do
  let(:user) { create :user }

  before do
    sign_in user
  end

  describe 'with recent sign in' do
    it 'returns http success' do
      get testing_format_path(format: :json)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'with old sign in' do
    it 'returns http unauthorized' do
      get '/'

      user.update! current_sign_in_at: 20.days.ago

      get testing_format_path(format: :json)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
