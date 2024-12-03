# frozen_string_literal: true

# app/controllers/integrations/sendjim/v3/import_contacts_controller.rb
module Integrations
  module Sendjim
    module V3
      # Support for importing SendJim contacts
      class ImportContactsController < Sendjim::V3::IntegrationsController
        # (GET) show Contacts import
        # /integrations/sendjim/v3/import_contacts
        # integrations_sendjim_v3_import_contacts_path
        # integrations_sendjim_v3_import_contacts_url
        def show
          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[import_contacts_show] }
        end

        # (PUT/PATCH) import Contacts
        # /integrations/sendjim/v3/import_contacts
        # integrations_sendjim_v3_import_contacts_path
        # integrations_sendjim_v3_import_contacts_url
        def update
          Integration::Sendjim::V3::Sendjim.delay(
            run_at:              Time.current,
            priority:            DelayedJob.job_priority('sendjim_import_contacts'),
            queue:               DelayedJob.job_queue('sendjim_import_contactss'),
            contact_id:          0,
            contact_campaign_id: 0,
            user_id:             current_user.id,
            triggeraction_id:    0,
            process:             'sendjim_import_contacts',
            group_process:       0,
            data:                { client_api_integration_id: @client_api_integration.id, user_id: current_user.id, new_contacts_only: params.dig(:new_contacts_only).to_bool }
          ).import_contacts(client_api_integration_id: @client_api_integration.id, user_id: current_user.id, new_contacts_only: params.dig(:new_contacts_only).to_bool)
          # Integration::Sendjim::V3::Sendjim.import_contacts(client_api_integration_id: @client_api_integration.id, user_id: current_user.id, new_contacts_only: params.dig(:new_contacts_only).to_bool)

          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[import_contacts_show] }
        end
      end
    end
  end
end
