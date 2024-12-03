# frozen_string_literal: true

# app/jobs/integrations/fieldpulse/v1/imports/contact_job.rb
module Integrations
  module Fieldpulse
    module V1
      module Imports
        class ContactJob < ApplicationJob
          # import Contacts from Fieldpulse clients
          # step 3 / import the Fieldpulse client
          # Integrations::Fieldpulse::V1::Imports::ContactJob.perform_now()
          # Integrations::Fieldpulse::V1::Imports::ContactJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldpulse::V1::Imports::ContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldpulse_import_contact').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:   (Integer)
          #   (req) fp_customer: (String)
          #   (req) user_id:     (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:fp_customer).is_a?(Hash) &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'fieldpulse', name: '')) &&
                          (fp_model = Integration::Fieldpulse::V1::Base.new(client_api_integration)) && fp_model.valid_credentials?

            fp_model.find_or_create_contact(fp_customer: args[:fp_customer])

            Integration::Fieldpulse::V1::Base.new.import_contacts_remaining_update(args[:user_id])
          end
        end
      end
    end
  end
end
