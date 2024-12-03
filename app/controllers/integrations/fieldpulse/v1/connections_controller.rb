# frozen_string_literal: true

# app/controllers/integrations/fieldpulse/v1/connections_controller.rb
module Integrations
  module Fieldpulse
    module V1
      class ConnectionsController < Fieldpulse::V1::IntegrationsController
        # (GET) show FieldPulse connection screen
        # /integrations/fieldpulse/v1/connections/edit
        # edit_integrations_fieldpulse_v1_connections_path
        # edit_integrations_fieldpulse_v1_connections_url
        def edit; end

        # (PATCH/PUT) update FieldPulse connection
        # /integrations/fieldpulse/v1/connections
        # integrations_fieldpulse_v1_connections_path
        # integrations_fieldpulse_v1_connections_url
        def update
          @client_api_integration.api_key            = params_update[:api_key]
          @client_api_integration.data[:credentials] = { version: Integration::Fieldpulse::Base.new(@client_api_integration).current_version }
          @client_api_integration.data[:company_id]  = Integration::Fieldpulse::V1::Base.new(@client_api_integration).teams&.first&.dig(:company_id).to_i
          @client_api_integration.save
        end

        private

        def params_update
          params.permit(:api_key)
        end
      end
    end
  end
end
