# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/connections_controller.rb
module Integrations
  module Pcrichard
    module V1
      class ConnectionsController < Pcrichard::V1::IntegrationsController
        # (GET) show the PC Richard connections screen
        # /integrations/pcrichard/v1/connections/edit
        # edit_integrations_pcrichard_v1_connections_path
        # edit_integrations_pcrichard_v1_connections_url
        def edit
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[connections_edit] }
        end

        # (PATCH/PUT) save the PC Richard Auth Token
        # /integrations/pcrichard/v1/connections
        # integrations_pcrichard_v1_connections_path
        # integrations_pcrichard_v1_connections_url
        def update
          @client_api_integration.update(credentials: params_credentials)

          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[connections_edit] }
        end

        private

        def params_credentials
          params.require(:credentials).permit(:auth_token)
        end
      end
    end
  end
end
