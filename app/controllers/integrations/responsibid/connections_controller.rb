# frozen_string_literal: true

# app/controllers/integrations/responsibid/connections_controller.rb
module Integrations
  module Responsibid
    # support for displaying user connections for ResponsiBid integration
    class ConnectionsController < Responsibid::IntegrationsController
      # (GET) ResponsiBid integration connections screen
      # /integrations/responsibid/connections
      # integrations_responsibid_connections_path
      # integrations_responsibid_connections_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[connections_show] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end
    end
  end
end
