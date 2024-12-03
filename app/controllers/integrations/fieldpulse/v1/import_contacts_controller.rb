# frozen_string_literal: true

# app/controllers/integrations/fieldpulse/v1/import_contacts_controller.rb
module Integrations
  module Fieldpulse
    module V1
      class ImportContactsController < Fieldpulse::V1::IntegrationsController
        # (GET) show import contacts screen
        # /integrations/fieldpulse/v1/import_contacts
        # integrations_fieldpulse_v1_import_contacts_path
        # integrations_fieldpulse_v1_import_contacts_url
        def show; end

        # (PUT/PATCH) import Contacts from FieldPulse customers
        # /integrations/fieldpulse/v1/import_contacts
        # integrations_fieldpulse_v1_import_contacts_path
        # integrations_fieldpulse_v1_import_contacts_url
        def update
          sanitized_params = import_params

          Integrations::Fieldpulse::V1::Imports::ContactsJob.perform_later(
            client_id: current_user.client_id,
            filter:    sanitized_params[:filter],
            user_id:   current_user.id
          )
        end

        private

        def import_params
          sanitized_params = params.require(:filter).permit(:active_only, :created_period, :updated_period)

          created_period = sanitized_params.dig(:created_period).to_s.split(' to ')
          created_at     = {
            after:  Chronic.parse(created_period.first)&.beginning_of_day,
            before: Chronic.parse(created_period.last)&.end_of_day
          }
          created_at[:after]  = created_at[:after] - 1.second if created_at[:after].present?
          created_at[:before] = created_at[:before] + 1.second if created_at[:before].present?

          updated_period = sanitized_params.dig(:updated_period).to_s.split(' to ')
          updated_at     = {
            after:  Chronic.parse(updated_period.first)&.beginning_of_day,
            before: Chronic.parse(updated_period.last)&.end_of_day
          }
          updated_at[:after]  = updated_at[:after] - 1.second if updated_at[:after].present?
          updated_at[:before] = updated_at[:before] + 1.second if updated_at[:before].present?

          {
            filter: {
              active_only: sanitized_params[:active_only].to_bool,
              created_at:,
              updated_at:
            }
          }
        end
        # example Parameters
      end
    end
  end
end
