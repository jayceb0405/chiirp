# frozen_string_literal: true

# app/controllers/integrations/jotform/v1/connections_controller.rb
module Integrations
  module Jotform
    module V1
      class ConnectionsController < Jotform::V1::IntegrationsController
        # (POST) create a JotForm Connection
        # /integrations/jotform/v1/connections
        # integrations_jotform_v1_connections_path
        # integrations_jotform_v1_connections_url
        def create
          @user_api_integration.update(params_api_key)
        end

        # /integrations/jotform/v1/connections
        # integrations_jotform_v1_connections_path
        # integrations_jotform_v1_connections_url
        def show; end

        private

        def params_api_key
          params.permit(:api_key)
        end
      end
    end
  end
end
