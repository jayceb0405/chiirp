# frozen_string_literal: true

# app/controllers/integrations/fieldroutes/v1/connections_controller.rb
module Integrations
  module Fieldroutes
    module V1
      class ConnectionsController < Fieldroutes::V1::IntegrationsController
        # (GET) show FieldRoutes connection screen
        # /integrations/fieldroutes/v1/connections/edit
        # edit_integrations_fieldroutes_v1_connections_path
        # edit_integrations_fieldroutes_v1_connections_url
        def edit; end

        # (PATCH/PUT) update FieldRoutes connection
        # /integrations/fieldroutes/v1/connections
        # integrations_fieldroutes_v1_connections_path
        # integrations_fieldroutes_v1_connections_url
        def update
          @client_api_integration.update(credentials: params_update.merge({ version: 1 }))
        end

        private

        def params_update
          params.permit(:auth_key, :auth_token, :subdomain)
        end
      end
    end
  end
end
