# frozen_string_literal: true

# app/controllers/integrations/salesrabbit/leads_controller.rb
module Integrations
  module Salesrabbit
    class LeadsController < Integrations::Salesrabbit::IntegrationsController
      # (GET) show SalesRabbit leads with Contacts
      # /integrations/salesrabbit/leads
      # integrations_salesrabbit_leads_path
      # integrations_salesrabbit_leads_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[leads] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      # (PUT/PATCH) synchronize SalesRabbit leads with Contacts
      # /integrations/salesrabbit/leads
      # integrations_salesrabbit_leads_path
      # integrations_salesrabbit_leads_url
      def update
        sr_client = Integrations::SalesRabbit::Base.new(@client_api_integration.api_key)
        result    = sr_client.leads(statuses: params_leads)

        Integration::Salesrabbit.update_contacts_from_leads(@client_api_integration.client_id, result) if sr_client.success? && result.present?

        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[leads] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      private

      def params_leads
        sanitized_params = params.permit(statuses: {})

        sanitized_params.dig(:statuses)&.select { |_k, v| v.to_i.positive? }&.keys || []
      end
    end
  end
end
