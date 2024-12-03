# frozen_string_literal: true

# app/controllers/integrations/calendly/integrations_controller.rb
module Integrations
  module Calendly
    # endpoints supporting Calendly integrations
    class IntegrationsController < ApplicationController
      before_action :set_contact, only: %i[appointment]
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :user_api_integration

      # (GET)
      # /integrations/calendly/integration/appointment/:contact_id
      # integrations_calendly_integration_appointment_path(:contact_id)
      # integrations_calendly_integration_appointment_url(:contact_id)
      def appointment
        respond_to do |format|
          format.js { render partial: 'integrations/calendly/js/show', locals: { cards: %w[appointment] } }
          format.html { redirect_to root_path }
        end
      end

      # (GET) edit interest rate integration
      # /integrations/calendly/integration/edit
      # edit_integrations_calendly_integration_path
      # edit_integrations_calendly_integration_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/calendly/js/show', locals: { cards: %w[form] } }
          format.html { render 'integrations/calendly/edit' }
        end
      end

      # (GET)
      # /integrations/calendly/integration/instructions
      # integrations_calendly_integration_instructions_path
      # integrations_calendly_integration_instructions_url
      def instructions
        respond_to do |format|
          format.js { render partial: 'integrations/calendly/js/show', locals: { cards: %w[instructions] } }
          format.html { render 'integrations/calendly/edit' }
        end
      end

      # (GET)
      # /integrations/calendly/integration
      # integrations_calendly_integration_path
      # integrations_calendly_integration_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/calendly/js/show', locals: { cards: %w[show] } }
          format.html { render 'integrations/calendly/show' }
        end
      end

      # (PUT/PATCH) update interest rate integration
      # /integrations/calendly/integration
      # integrations_calendly_integration_path
      # integrations_calendly_integration_url
      def update
        @user_api_integration.update(params_user_api_integration)

        respond_to do |format|
          format.js { render partial: 'integrations/calendly/js/show', locals: { cards: %w[form] } }
          format.html { render 'integrations/calendly/edit' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('calendly')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Calendly Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def params_user_api_integration
        response = params.require(:user_api_integration).permit(:embed_script)

        response[:embed_script] = response[:embed_script].gsub('{script', '<script').gsub('{/script}', '</script>') if response.include?(:embed_script)

        response
      end

      def set_contact
        return if (@contact = Contact.find_by(id: params[:contact_id]))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def user_api_integration
        @user_api_integration = current_user.user_api_integrations.find_or_create_by(target: 'calendly', name: '')
      end
    end
  end
end
