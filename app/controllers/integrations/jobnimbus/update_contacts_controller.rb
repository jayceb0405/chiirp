# frozen_string_literal: true

# app/controllers/integrations/jobnimbus/update_contacts_controller.rb
module Integrations
  module Jobnimbus
    # support for updating Contact data from JobNimbus contact data
    class UpdateContactsController < Jobnimbus::IntegrationsController
      # (GET) show Contacts import
      # /integrations/jobnimbus/update_contacts
      # integrations_jobnimbus_update_contacts_path
      # integrations_jobnimbus_update_contacts_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[update_contacts_show] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end

      # (PUT/PATCH) import Price Book
      # /integrations/jobnimbus/update_contacts
      # integrations_jobnimbus_update_contacts_path
      # integrations_jobnimbus_update_contacts_url
      def update
        Integrations::Jobnimbus::V1::Imports::ContactsJob.perform_later(
          client_id:         @client_api_integration.client_id,
          new_contacts_only: params.dig(:new_contacts_only).to_bool,
          user_id:           current_user.id
        )

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[update_contacts_show] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end
    end
  end
end
