# frozen_string_literal: true

# app/controllers/integrations/salesrabbit/contacts_controller.rb
module Integrations
  module Salesrabbit
    class ContactsController < Integrations::Salesrabbit::IntegrationsController
      # (GET) show SalesRabbit new Contact actions
      # /integrations/salesrabbit/contact
      # integrations_salesrabbit_contact_path
      # integrations_salesrabbit_contact_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[contacts] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      # (PUT/PATCH) save SalesRabbit new Contact actions
      # /integrations/salesrabbit/contact
      # integrations_salesrabbit_contact_path
      # integrations_salesrabbit_contact_url
      def update
        @client_api_integration.update(new_contact_actions: params_contact)

        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[contacts] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      private

      def params_contact
        sanitized_params = params.require(:new_contact_actions).permit(:campaign_id, :group_id, :stage_id, :tag_id, stop_campaign_ids: [])
        sanitized_params[:stop_campaign_ids] = sanitized_params[:stop_campaign_ids]&.compact_blank
        sanitized_params[:stop_campaign_ids] = [0] if sanitized_params[:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end
