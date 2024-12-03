# frozen_string_literal: true

# app/models/integration/dope/v1/dope.rb
module Integration
  module Dope
    module V1
      # Dope data processing
      class Dope < ApplicationRecord
        # send a Contact to Dope to start an automation
        # Integration::Dope::V1::Dope.start_automation(contact_id: Integer, tag_id: Integer)
        def self.start_automation(args = {})
          contact_id = args.dig(:contact_id).to_i
          tag_id     = args.dig(:tag_id).to_i

          return if contact_id.zero? || tag_id.zero? ||
                    (contact = Contact.find_by(id: contact_id)).nil? ||
                    (client_api_integration = ClientApiIntegration.find_by(client_id: contact.client_id, target: 'dope_marketing', name: '')).nil? ||
                    client_api_integration.client.integrations_allowed.exclude?('dope_marketing')

          client_api_integration.automations.map(&:symbolize_keys).map { |automation| automation.dig(:tag_id) }&.exclude?(tag_id)

          dp_client = Integrations::Doper::V1::Dope.new(client_api_integration.api_key)

          client_api_integration.automations.map(&:symbolize_keys).select { |a| a.dig(:tag_id) == tag_id }.each do |automation|
            dp_client.automation(
              automation_id: automation.dig(:id).to_s,
              firstname:     contact.firstname,
              lastname:      contact.lastname,
              address_01:    contact.address1,
              address_02:    contact.address2,
              city:          contact.city,
              state:         contact.state,
              postal_code:   contact.zipcode
            )
            contact.postcards.create(
              client_id: contact.client_id,
              tag_id:,
              target:    'dope_marketing',
              card_id:   automation.dig(:id).to_s,
              card_name: automation.dig(:name).to_s,
              result:    dp_client.success?.to_s
            )
          end
        end
      end
    end
  end
end
