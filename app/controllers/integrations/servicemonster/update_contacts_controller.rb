# frozen_string_literal: true

# app/controllers/integrations/servicemonster/update_contacts_controller.rb
module Integrations
  module Servicemonster
    # support for updating Contact data from Housecall Pro customer data
    class UpdateContactsController < Servicemonster::IntegrationsController
      # (GET) show Contacts import
      # /integrations/servicemonster/update_contacts
      # integrations_servicemonster_update_contacts_path
      # integrations_servicemonster_update_contacts_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[update_contacts_show] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (PUT/PATCH) import Price Book
      # /integrations/servicemonster/update_contacts
      # integrations_servicemonster_update_contacts_path
      # integrations_servicemonster_update_contacts_url
      def update
        Integration::Servicemonster.delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('servicemonster_import_accounts'),
          queue:               DelayedJob.job_queue('servicemonster_import_accounts'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             current_user.id,
          triggeraction_id:    0,
          process:             'servicemonster_import_accounts',
          group_process:       0,
          data:                { client_api_integration: @client_api_integration, client_id: @client_api_integration.client_id, user_id: current_user.id, new_contacts_only: params.dig(:new_contacts_only).to_bool }
        ).import_accounts(client_api_integration: @client_api_integration, user_id: current_user.id, new_contacts_only: params.dig(:new_contacts_only).to_bool)

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[update_contacts_show] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end
    end
  end
end
