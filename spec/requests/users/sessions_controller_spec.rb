# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController, type: :request do
  let(:user) { create :user }

  describe 'GET /users/sign_in' do
    it 'returns http success' do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /users/sign_in' do
    describe 'with valid credentials' do
      it 'returns redirect to 2FA page' do
        post user_session_path, params: { user: { email: user.email, password: user.password } }
        expect(response).to redirect_to(method_user_two_factor_path)
      end

      describe 'and all caps' do
        it 'returns redirect to 2FA page' do
          post user_session_path, params: { user: { email: user.email.upcase, password: user.password } }
          expect(response).to redirect_to(method_user_two_factor_path)
        end
      end
    end

    describe 'with invalid credentials' do
      it 'returns redirect to sign in page' do
        post user_session_path, params: { user: { email: user.email, password: 'asdf' } }
        expect(response).to redirect_to(new_user_session_path)

        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'locks the account' do
        5.times do
          post user_session_path, params: { user: { email: user.email, password: 'asdf' } }
          expect(response).to redirect_to(new_user_session_path)
        end

        expect(user.reload.access_locked?).to be true
      end
    end

    describe 'with incorrect email address' do
      it 'returns redirect to sign in page' do
        post user_session_path, params: { user: { email: 'asdf@asdf.com', password: 'asdf' } }
        expect(response).to redirect_to(new_user_session_path)

        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
