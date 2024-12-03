# frozen_string_literal: true

module Integrations
  module Cardx
    class ConnectionsController < Integrations::Cardx::IntegrationsController
      # (GET) CallRail integration configuration screen
      # /integrations/cardx/connections/edit
      # edit_integrations_cardx_connections_path
      # edit_integrations_cardx_connections_url
      def edit
        render partial: 'integrations/cardx/js/show', locals: { cards: %w[connections_edit] }
      end

      # (PATCH/PUT) CallRail integration configuration save
      # /integrations/cardx/connections
      # integrations_cardx_connections_path
      # integrations_cardx_connections_url
      def update
        @client_api_integration.update(params_credentials)

        render partial: 'integrations/cardx/js/show', locals: { cards: %w[menu connections_edit] }
      end

      private

      def params_credentials
        params.require(:credentials).permit(:account, :redirect)
      end
    end
  end
end
