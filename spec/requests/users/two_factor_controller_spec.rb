# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::TwoFactorController, type: :request do
  let(:user) { create :user, otp_secret: ROTP::Base32.random, otp_secret_at: Time.now.to_i }

  before do
    # get past session controller by sigining in
    post(user_session_path, params: { user: { email: user.email, password: user.password } })
  end

  describe 'OTP method' do
    it 'should return http success' do
      get(method_user_two_factor_path)
      expect(response).to have_http_status(:ok)
    end

    describe 'selecting method' do
      %w[sms email].each do |method|
        it 'should return redirect to attempt page' do
          patch(users_2fa_method_path, params: { user: { otp_method: method } })
          expect(response).to redirect_to(attempt_user_two_factor_path)
        end
      end

      it 'should return redirect to select otp again' do
        patch(users_2fa_method_path, params: { user: { otp_method: 'asdf' } })
        expect(response).to redirect_to(method_user_two_factor_path)
      end
    end
  end

  it 'should not allow access to attempt page without method selection' do
    get(attempt_user_two_factor_path)
    expect(response).to redirect_to(method_user_two_factor_path)
  end

  describe 'OTP attempt' do
    before do
      patch(users_2fa_method_path, params: { user: { otp_method: 'sms' } })
    end

    describe 'GET /users/2fa' do
      it 'returns http success' do
        get(attempt_user_two_factor_path, params: { cookies: { otp_user_id: user.id } })
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /users/2fa' do
      describe 'with valid OTP' do
        it 'returns redirect to root page' do
          patch(attempt_user_two_factor_path, params: { user: { otp_attempt: user.reload.otp_code } })
          expect(response).to redirect_to(root_path)

          get root_path
          expect(response).to have_http_status(:success)
        end
      end

      describe 'with invalid OTP' do
        it 'returns redirect to sign in page' do
          patch(user_session_path, params: { user: { otp_attempt: '111111' } })
          expect(response).to redirect_to(user_session_path)

          get root_path
          expect(response).to redirect_to(user_session_path)
        end
      end
    end
  end
end
