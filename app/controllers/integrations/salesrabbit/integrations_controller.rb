# frozen_string_literal: true

# app/controllers/integrations/salesrabbit/integrations_controller.rb
module Integrations
  module Salesrabbit
    # endpoints supporting Salesrabbit integrations
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :client_api_integration

      # (GET) show SalesRabbit edit page
      # /integrations/salesrabbit/integration/edit
      # edit_integrations_salesrabbit_integration_path
      # edit_integrations_salesrabbit_integration_url
      def edit
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      # (GET) show SalesRabbit Instructions
      # /integrations/salesrabbit/integration/instructions
      # integrations_salesrabbit_integration_instructions_path
      # integrations_salesrabbit_integration_instructions_url
      def instructions
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[instructions] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('salesrabbit')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access SalesRabbit Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'salesrabbit')
      end
    end
  end
end
