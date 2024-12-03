# frozen_string_literal: true

# app/controllers/integrations/thumbtack/v2/connections_controller.rb
module Integrations
  module Thumbtack
    module V2
      class ConnectionsController < Thumbtack::IntegrationsController
        # (DELETE) delete a Thumbtack integration
        # /integrations/thumbtack/v2/connections
        # integrations_thumbtack_v2_connections_path
        # integrations_thumbtack_v2_connections_url
        def destroy
          if Integration::Thumbtack::V2::Base.new(@client_api_integration).disconnect_account
            @client_api_integration.update(auth_code: SecureRandom.uuid)

            sweetalert_success('Success!', 'Connection to Thumbtack was disconnected successfully.', '', { persistent: 'OK' })
          else
            sweetalert_error('Unathorized Access!', 'Unable to locate an account with Thumbtack credentials received. Please contact your account admin.', '', { persistent: 'OK' })
          end

          redirect_to integrations_thumbtack_integration_path
        end

        # (GET) Thumbtack integration configuration screen
        # /integrations/thumbtack/v2/connections/edit
        # edit_integrations_thumbtack_v2_connections_path
        # edit_integrations_thumbtack_v2_connections_url
        def edit; end
      end
    end
  end
end
