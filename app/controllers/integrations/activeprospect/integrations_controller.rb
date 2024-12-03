# frozen_string_literal: true

# app/controllers/integrations/activeprospect/integrations_controller.rb
module Integrations
  module Activeprospect
    # endpoints supporting Activeprospect integrations
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :user_api_integration

      # (GET) edit ActiveProspect integration
      # /integrations/activeprospect/integration/edit
      # edit_integrations_activeprospect_integration_path
      # edit_integrations_activeprospect_integration_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/activeprospect/js/show', locals: { cards: %w[form] } }
          format.html { render 'integrations/activeprospect/edit' }
        end
      end

      # (GET) show ActiveProspect instructions
      # /integrations/activeprospect/integration/instructions
      # integrations_activeprospect_integration_instructions_path
      # integrations_activeprospect_integration_instructions_url
      def instructions
        respond_to do |format|
          format.js { render partial: 'integrations/activeprospect/js/show', locals: { cards: %w[instructions] } }
          format.html { render 'integrations/activeprospect/edit' }
        end
      end

      # (GET) show ActiveProspect integration
      # /integrations/activeprospect/integration
      # integrations_activeprospect_integration_path
      # integrations_activeprospect_integration_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/activeprospect/js/show', locals: { cards: %w[show] } }
          format.html { render 'integrations/activeprospect/show' }
        end
      end

      # (PUT/PATCH) update ActiveProspect integration
      # /integrations/activeprospect/integration
      # integrations_activeprospect_integration_path
      # integrations_activeprospect_integration_url
      def update
        @user_api_integration.update(params_user_api_integration)

        respond_to do |format|
          format.js { render partial: 'integrations/activeprospect/js/show', locals: { cards: %w[form] } }
          format.html { render 'integrations/activeprospect/edit' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('activeprospect')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Trusted Form Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def params_user_api_integration
        response = params.require(:user_api_integration).permit(:trusted_form_script)

        response[:trusted_form_script] = response[:trusted_form_script].gsub('{script', '<script').gsub('{/script}', '</script>') if response.include?(:trusted_form_script)

        response
      end

      def user_api_integration
        @user_api_integration = current_user.user_api_integrations.find_or_create_by(target: 'activeprospect', name: '')
      end
    end
  end
end
