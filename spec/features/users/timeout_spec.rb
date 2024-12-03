# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sign in', type: :feature, js: true, special: true do
  let(:password) { SecureRandom.alphanumeric(20) }
  let(:user) { create :user, phone: '7145551212' }

  describe 'after timeout it redirects to sign in' do
    before do
      user.update!(password:)

      visit '/users/sign_in'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      click_button 'Sign In'

      expect(page).to have_content('Choose Authentication Method')
      click_button 'Send'

      expect(page).to have_content('Verify Authentication Code')
      fill_in 'input_otp_attempt', with: user.reload.otp_code
      click_button 'Verify'

      visit testing_format_path
    end

    it 'for turbo frame requests' do
      click_on 'turbo frame test'
      expect(page).to have_current_path(new_user_session_path(expired: true))
      expect(page).to have_content('Your session has expired')
    end

    it 'for turbo stream requests' do
      click_on 'turbo stream test'
      expect(page).to have_current_path(new_user_session_path(expired: true))
      expect(page).to have_content('Your session has expired')
    end

    it 'for js requests' do
      click_on 'js test'
      expect(page).to have_current_path(new_user_session_path(expired: true))
      expect(page).to have_content('Your session has expired')
    end

    it 'for html requests' do
      click_on 'html test'
      expect(page).to have_current_path(new_user_session_path(expired: true))
      expect(page).to have_content('Your session has expired')
    end
  end
end
