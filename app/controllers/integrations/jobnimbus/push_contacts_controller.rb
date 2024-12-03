# frozen_string_literal: true

# app/controllers/integrations/jobnimbus/push_contacts_controller.rb
module Integrations
  module Jobnimbus
    # support for configuring actions to push leads to JobNimbus
    class PushContactsController < Jobnimbus::IntegrationsController
      # (GET) show api_key edit screen
      # /integrations/jobnimbus/push_contacts/edit
      # edit_integrations_jobnimbus_push_contacts_path
      # edit_integrations_jobnimbus_push_contacts_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[push_contacts_edit] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end

      # (PATCH/PUT) update api_key
      # /integrations/jobnimbus/push_contacts
      # integrations_jobnimbus_push_contacts_path
      # integrations_jobnimbus_push_contacts_url
      def update
        @client_api_integration.update(push_contacts_tag_id: params_tag_id.dig(:customer, :tag_id).to_i)

        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[push_contacts_edit] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end

      private

      def params_tag_id
        params.require(:push_leads).permit(customer: [:tag_id])
      end
    end
  end
end
