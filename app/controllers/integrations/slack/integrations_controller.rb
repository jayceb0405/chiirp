# frozen_string_literal: true

# app/controllers/integrations/slack/integrations_controller.rb
module Integrations
  module Slack
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :user_api_integration

      # (GET) show Slack integration
      # /integrations/slack/integration
      # integrations_slack_integration_path
      # integrations_slack_integration_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[show_overview] } }
          format.html { render 'integrations/slack/show' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('slack')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Slack Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_path}'" and return false }
          format.html { redirect_to integrations_path and return false }
        end
      end

      def user_api_integration
        @user_api_integration = current_user.user_api_integrations.find_or_create_by(target: 'slack', name: '')
      end
    end
  end
end
