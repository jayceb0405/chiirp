# frozen_string_literal: true

# app/controllers/integrations/five9/integrations_controller.rb
module Integrations
  module Five9
    # endpoints supporting Five9 integrations
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :client_api_integration

      # (GET) show instructions page for Five9 integration
      # /integrations/five9/integration/instructions
      # integrations_five9_integration_instructions_path
      # integrations_five9_integration_instructions_url
      def instructions
        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[instructions] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) show Five9 integration
      # /integrations/five9/integration
      # integrations_five9_integration_path
      # integrations_five9_integration_url
      def show
        respond_to do |format|
          format.html { render 'integrations/five9/show' }
          format.js   { render partial: 'integrations/five9/js/show', locals: { cards: %w[overview] } }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('five9')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Five9 Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'five9', name: '')
      end
    end
  end
end
