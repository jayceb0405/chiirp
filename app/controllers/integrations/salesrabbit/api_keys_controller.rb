# frozen_string_literal: true

# app/controllers/integrations/salesrabbit/api_keys_controller.rb
module Integrations
  module Salesrabbit
    class ApiKeysController < Integrations::Salesrabbit::IntegrationsController
      # (GET) show SalesRabbit API Key
      # /integrations/salesrabbit/api_key
      # integrations_salesrabbit_api_key_path
      # integrations_salesrabbit_api_key_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[api_key] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      # (PUT/PATCH) save a SalesRabbit API key
      # /integrations/salesrabbit/api_key
      # integrations_salesrabbit_api_key_path
      # integrations_salesrabbit_api_key_url
      def update
        @client_api_integration.update(params_api_key)

        if @client_api_integration.api_key.present?
          sr_client = Integrations::SalesRabbit::Base.new(@client_api_integration.api_key)

          result = sr_client.statuses
          @client_api_integration.update(statuses: result) if sr_client.success?

          result = sr_client.users
          @client_api_integration.update(users: result) if sr_client.success?
        else
          @client_api_integration.update(statuses: [], users: [], users_users: {}, status_actions: {}, last_request_time: '')
        end

        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[api_key] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      private

      def params_api_key
        response = params.require(:client_api_integration).permit(:api_key)

        response[:api_key] ||= ''

        response
      end
    end
  end
end
