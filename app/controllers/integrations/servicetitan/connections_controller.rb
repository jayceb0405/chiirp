# frozen_string_literal: true

# app/controllers/integrations/servicetitan/connections_controller.rb
module Integrations
  module Servicetitan
    class ConnectionsController < Servicetitan::IntegrationsController
      # (GET) show ServiceTitan api key form
      # /integrations/servicetitan/connection
      # integrations_servicetitan_connection_path
      # integrations_servicetitan_connection_url
      def show
        render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[connection] }
      end

      # (PUT/PATCH) update the ServiceTitan api key
      # /integrations/servicetitan/connection
      # integrations_servicetitan_connection_path
      # integrations_servicetitan_connection_url
      def update
        @client_api_integration.update(credentials: params_api_keys.dig(:credentials) || {})

        render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[connection] }
      end

      private

      def params_api_keys
        sanitized_params = params.permit(credentials: %i[app_id client_id client_secret tenant_id])

        sanitized_params[:credentials][:app_id]        = (sanitized_params.dig(:credentials, :app_id) || '02').to_s.strip
        sanitized_params[:credentials][:client_id]     = sanitized_params.dig(:credentials, :client_id).to_s.strip
        sanitized_params[:credentials][:client_secret] = sanitized_params.dig(:credentials, :client_secret).to_s.strip
        sanitized_params[:credentials][:tenant_id]     = sanitized_params.dig(:credentials, :tenant_id).to_s.strip

        sanitized_params
      end
    end
  end
end
