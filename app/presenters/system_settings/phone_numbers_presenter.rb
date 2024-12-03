# frozen_string_literal: true

# app/presenters/system_settings/phone_numbers_presenter.rb
module SystemSettings
  class PhoneNumbersPresenter
    attr_reader :user

    def client_array
      Client.where(tenant: I18n.t('tenant.id')).pluck(:name, :id).sort
    end

    def vendor_array
      [
        %w[Bandwidth bandwidth],
        %w[Sinch sinch],
        %w[Twilio twilio]
      ]
    end
  end
end
