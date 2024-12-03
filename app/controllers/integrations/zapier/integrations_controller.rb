# frozen_string_literal: true

# app/controllers/integrations/zapier/integrations_controller.rb
module Integrations
  module Zapier
    # endpoints supporting Zapier integrations
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!

      # (GET) show Zapier integration Zaps
      # /integrations/zapier/integrations
      # integrations_zapier_integrations_path
      # integrations_zapier_integrations_url
      def show
        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" }
          format.html { render 'integrations/zapier/show' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('zapier')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Zapier Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
