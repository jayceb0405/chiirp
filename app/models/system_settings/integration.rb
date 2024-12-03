# frozen_string_literal: true

# app/models/system_settings/integration.rb
module SystemSettings
  class Integration < ApplicationRecord
    after_initialize  :apply_defaults, if: :new_record?
    before_validation :before_validation_actions

    has_one_attached :logo_image

    validates :company_name, presence: true, length: { minimum: 2 }, uniqueness: true

    def initials
      self.company_name.split.pluck(0).join
    end

    def accessible_to_user?(user)
      if self.controller.present? && self.controller.split('_').length == 2 && self.integration.present?
        user.access_controller?(*self.controller.split('_')) && user.client.integrations_allowed.include?(self.integration)
      else
        true
      end
    end

    def configured_for_client_and_user?(client, user)
      client.integration_configured?(self.integration) || user.integration_configured?(self.integration)
    end

    private

    def apply_defaults
      self.company_name ||= 'New Integration'
    end

    def before_validation_actions
      self.phone_number = self.phone_number.clean_phone(802) if self.phone_number.present?
    end
  end
end
