# frozen_string_literal: true

# app/controllers/integrations/five9/v12/connections_controller.rb
module Integrations
  module Five9
    module V12
      class ConnectionsController < Five9::IntegrationsController
        # (GET) show Five9 connection screen
        # /integrations/five9/v12/connections/edit
        # edit_integrations_five9_v12_connections_path
        # edit_integrations_five9_v12_connections_url
        def edit; end

        # (PATCH/PUT) update Five9 connection
        # /integrations/five9/v12/connections
        # integrations_five9_v12_connections_path
        # integrations_five9_v12_connections_url
        def update
          @client_api_integration.update(credentials: params_update.to_hash.merge({ version: 12 }))
        end

        private

        def params_update
          params.require(:credentials).permit(:password, :username)
        end
      end
    end
  end
end
