# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sign in', type: :feature do
  let(:password) { 'asdfsadf' }
  let(:user) { create :user }

  before do
    user.update!(password:)
  end

  describe 'With valid credentials' do
    it 'signs in' do
      visit '/users/sign_in'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      click_on 'Log in'

      expect(page).to have_content('2-step authentication method')
      choose 'Text message to'
      click_on 'Send'

      expect(page).to have_content('A code was sent to your phone at')
      fill_in 'input_otp_attempt', with: user.reload.otp_code
      click_on 'Verify'

      expect(page).to have_content('We want you to succeed!')
    end

    describe 'with invalid OTP' do
      it 'rejects sign in' do
        visit '/users/sign_in'
        fill_in 'Email', with: user.email
        fill_in 'Password', with: password
        click_on 'Log in'

        expect(page).to have_content('2-step authentication method')
        click_on 'Send'

        expect(page).to have_content('A code was sent to your email address.')
        fill_in 'input_otp_attempt', with: '111111'
        click_on 'Verify'

        expect(page).to have_content('Invalid one time authentication code.')
        expect(page.current_path).to eq('/users/sign_in')
      end
    end
  end

  describe 'With invalid credentials' do
    it 'rejects sign in' do
      visit '/users/sign_in'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: "#{password}asdf"
      click_on 'Log in'

      expect(page).to have_content('Invalid email address or password.')
      expect(page.current_path).to eq('/users/sign_in')
    end

    it 'rejects sign in' do
      visit '/users/sign_in'
      fill_in 'Email', with: 'asdf@asdf.com'
      fill_in 'Password', with: password
      click_on 'Log in'

      expect(page).to have_content('Invalid email address or password.')
      expect(page.current_path).to eq('/users/sign_in')
    end
  end
end
