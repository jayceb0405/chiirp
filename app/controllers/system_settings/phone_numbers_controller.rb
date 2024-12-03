# frozen_string_literal: true

# app/controllers/system_settings/phone_numbers_controller.rb
module SystemSettings
  # System Settings endpoints supporting New Phone Numbers
  class PhoneNumbersController < SystemSettings::SystemSettingsController
    # (POST) send a Toast to all Users
    # /system_settings/phone_numbers
    # system_settings_phone_numbers_path
    # system_settings_phone_numbers_url
    def create
      Twnumber.create(phone_number_params)

      render partial: 'system_settings/js/show', locals: { cards: %w[phone_number_new] }
    end

    # (GET) edit a Version
    # /system_settings/toast/edit
    # edit_system_settings_toast_path
    # edit_system_settings_toast_url
    def new
      render partial: 'system_settings/js/show', locals: { cards: %w[phone_number_new] }
    end

    private

    def phone_number_params
      params.require(:phone_number).permit(:phonenumber, :client_id, :name, :vendor_id, :phone_vendor)
    end
  end
end
