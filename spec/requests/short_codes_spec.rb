# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShortCodesController, type: :request do
  let(:short_code) { create :short_code }

  describe 'GET /show' do
    it 'returns http success' do
      get short_code_path(short_code)
      expect(response).to have_http_status(:found)
    end

    it 'redirects to the correct url' do
      get short_code_path(short_code)
      expect(response).to redirect_to short_code.url
    end
  end
end
