# frozen_string_literal: true

# app/presenters/system_settings/toasts_presenter.rb
module SystemSettings
  # variables required by Facebook integration views
  class ToastsPresenter
    attr_reader :user

    def initialize(args = {})
      @user = args.dig(:user)
    end

    def user=(user)
      @user = case user
              when User
                user
              when Integer
                User.find_by(id: user)
              end
    end
  end
end
