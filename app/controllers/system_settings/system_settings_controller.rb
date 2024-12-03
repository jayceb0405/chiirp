# frozen_string_literal: true

# app/controllers/system_settings/system_settings_controller.rb
module SystemSettings
  # general System Settings endpoints
  class SystemSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!

    # (GET) show System Settings
    # /system_settings
    # system_settings_path
    # system_settings_url
    def index
      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[overview] } }
        format.html { render 'system_settings/index' }
      end
    end

    private

    def authorize_user!
      super

      return if action_name == 'history'
      return if current_user.super_admin?

      raise ExceptionHandlers::UserNotAuthorized.new('System Settings', root_path)
    end
  end
end
