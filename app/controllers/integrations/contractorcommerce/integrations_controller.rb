# frozen_string_literal: true

# app/controllers/integrations/contractorcommerce/integrations_controller.rb
module Integrations
  module Contractorcommerce
    class IntegrationsController < ApplicationController
      before_action :client
      before_action :client_api_integration

      CURRENT_VERSION = '1'

      # (GET) show Contractor Commerce main integration screen
      # /integrations/contractorcommerce/integration
      # integrations_contractorcommerce_integration_path
      # integrations_contractorcommerce_integration_url
      def show
        @version = @client_api_integration&.data&.dig('credentials', 'version') || CURRENT_VERSION
      end

      private

      def authorize_user!
        super

        return true if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('contractorcommerce')

        raise ExceptionHandlers::UserNotAuthorized.new('Contractor Commerce Integrations', root_path)
      end

      def client
        @client = current_user.client
      end

      def client_api_integration
        return true if (@client_api_integration = @client.client_api_integrations.find_or_create_by(target: 'contractorcommerce', name: ''))

        raise ExceptionHandlers::UserNotAuthorized.new('Contractor Commerce Integrations', root_path)
      end

      def params_endpoint
        params.require(:data).permit(webHookEvent: %i[accountId appId itemId occuredAt topic])
      end

      def params_auth_code
        params.permit(:code, :scope, :state)
      end
    end
  end
end
