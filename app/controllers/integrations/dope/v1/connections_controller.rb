# frozen_string_literal: true

# app/controllers/integrations/dope/v1/connections_controller.rb
module Integrations
  module Dope
    module V1
      # DropFunnels integration endpoints supporting API Key
      class ConnectionsController < Dope::V1::IntegrationsController
        # (GET) show Connections
        # /integrations/dope/v1/connection
        # integrations_dope_v1_connection_path
        # integrations_dope_v1_connection_url
        def show
          render partial: 'integrations/dope/v1/js/show', locals: { cards: %w[connection_show] }
        end

        # (PUT/PATCH) save Dope API Key
        # /integrations/dope/v1/automations/:id
        # integrations_dope_v1_connection_path(:id)
        # integrations_dope_v1_connection_url(:id)
        def update
          @client_api_integration.update(params_api_key)

          render partial: 'integrations/dope/v1/js/show', locals: { cards: %w[connection_show] }
        end

        private

        def params_api_key
          params.require(:client_api_integration).permit(:api_key)
        end
      end
    end
  end
end
