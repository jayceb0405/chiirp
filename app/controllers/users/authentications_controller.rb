# frozen_string_literal: true

# app/controllers/users/authentications_controller.rb
module Users
  class AuthenticationsController < ApplicationController
    def destroy
      current_user.update(provider: nil, uid: nil)
      # rubocop:disable Rails/I18nLocaleTexts
      redirect_to edit_user_registration_path, notice: 'Facebook Account Unlinked'
      # rubocop:enable Rails/I18nLocaleTexts
    end
  end
end
