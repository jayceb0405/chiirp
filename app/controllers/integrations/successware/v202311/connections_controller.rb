# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/connections_controller.rb
module Integrations
  module Successware
    module V202311
      class ConnectionsController < Successware::IntegrationsController
        # (DELETE) delete a Successware integration
        # /integrations/successware/v202311/connections
        # integrations_successware_v202311_connections_path
        # integrations_successware_v202311_connections_url
        def destroy
          Integration::Successware::V202311::Base.new(@client_api_integration).disconnect_account

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[connections_edit] }
        end

        # (GET) Successware integration configuration screen
        # /integrations/successware/v202311/connections/edit
        # edit_integrations_successware_v202311_connections_path
        # edit_integrations_successware_v202311_connections_url
        def edit
          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[connections_edit] }
        end
      end
    end
  end
end
