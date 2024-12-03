# frozen_string_literal: true

# app/controllers/integrations/jobnimbus/connections_controller.rb
module Integrations
  module Jobnimbus
    # support for displaying user connections for JobNimbus integration
    class ConnectionsController < Jobnimbus::IntegrationsController
      # (GET) JobNimbus integration connections screen
      # /integrations/jobnimbus/connections
      # integrations_jobnimbus_connections_path
      # integrations_jobnimbus_connections_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[connections_show] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end

      # (PUT/PATCH) update JobNimbus API key
      # /integrations/jobnimbus/connections
      # integrations_jobnimbus_connections_path
      # integrations_jobnimbus_connections_url
      def update
        @client_api_integration.update(params_api_key)

        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[connections_show] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end

      private

      def params_api_key
        params.require(:client_api_integration).permit(:api_key)
      end
    end
  end
end
