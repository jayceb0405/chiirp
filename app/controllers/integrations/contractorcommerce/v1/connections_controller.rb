# frozen_string_literal: true

# app/controllers/integrations/contractorcommerce/v1/connections_controller.rb
module Integrations
  module Contractorcommerce
    module V1
      class ConnectionsController < Contractorcommerce::IntegrationsController
        # (DELETE) delete a Contractor Commerce integration
        # /integrations/contractorcommerce/v1/connections
        # integrations_contractorcommerce_v1_connections_path
        # integrations_contractorcommerce_v1_connections_url
        def destroy
          sweetalert_success('Success!', 'Connection to Contractor Commerce was disconnected successfully.', '', { persistent: 'OK' })

          redirect_to integrations_contractorcommerce_integration_path
        end

        # (GET) Contractor Commerce integration configuration screen
        # /integrations/contractorcommerce/v1/connections/edit
        # edit_integrations_contractorcommerce_v1_connections_path
        # edit_integrations_contractorcommerce_v1_connections_url
        def edit; end
      end
    end
  end
end
