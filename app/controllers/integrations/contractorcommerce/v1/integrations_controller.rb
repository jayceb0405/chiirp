# frozen_string_literal: true

# app/controllers/integrations/contractorcommerce/v1/integrations_controller.rb
module Integrations
  module Contractorcommerce
    module V1
      class IntegrationsController < Contractorcommerce::IntegrationsController
        before_action :authenticate_webhook
        skip_before_action :verify_authenticity_token, only: %i[webhook]
        skip_before_action :client, only: %i[webhook]
        skip_before_action :client_api_integration, only: %i[webhook]

        # (POST) Contractor Commerce webhook webhook for leads
        # /integrations/contractorcommerce/v1/webhook/lead
        # integrations_contractorcommerce_v1_webhook_lead_path
        # integrations_contractorcommerce_v1_webhook_lead_url
        def webhook
          # sanitized_params = params_endpoint_lead
          client_api_integration_count = 1

          # ClientApiIntegration.joins(:client).where(target: 'contractorcommerce', name: '').where('client_api_integrations.data @> ?', { credentials: { account: { business_pk: sanitized_params.dig(:business, :businessID) } } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
          # end

          if client_api_integration_count.positive?
            head :ok
          else
            head :not_found
          end
        end

        # (GET) show Contractor Commerce overview
        # /integrations/contractorcommerce/v1
        # integrations_contractorcommerce_v1_path
        # integrations_contractorcommerce_v1_url
        def show; end

        private

        def authenticate_webhook
        end
      end
    end
  end
end
