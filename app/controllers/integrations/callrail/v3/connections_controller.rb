# frozen_string_literal: true

module Integrations
  module Callrail
    module V3
      class ConnectionsController < Integrations::Callrail::V3::IntegrationsController
        # (GET) CallRail integration configuration screen
        # /integrations/callrail/v3/connections/edit
        # edit_integrations_callrail_v3_connections_path
        # edit_integrations_callrail_v3_connections_url
        def edit
          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[connections_edit] }
        end

        # (PATCH/PUT) CallRail integration configuration save
        # /integrations/callrail/v3/connections
        # integrations_callrail_v3_connections_path
        # integrations_callrail_v3_connections_url
        def update
          @client_api_integration.update(credentials: params_credentials)

          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[menu connections_edit] }
        end

        private

        def params_credentials
          params.require(:credentials).permit(:api_key, :webhook_signature_token)
        end
      end
    end
  end
end
