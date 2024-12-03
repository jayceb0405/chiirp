# frozen_string_literal: true

# app/controllers/integrations/slack/notifications_controller.rb
module Integrations
  module Slack
    class NotificationsController < Slack::IntegrationsController
      # (GET) Slack notifications configuration screen
      # /integrations/slack/notifications/edit
      # edit_integrations_slack_notifications_path
      # edit_integrations_slack_notifications_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[edit_notifications] } }
          format.html { redirect_to integrations_slack_integration_path }
        end
      end

      # (PATCH/PUT) save notification selections
      # /integrations/slack/notifications
      # integrations_slack_notifications_path
      # integrations_slack_notifications_url
      def update
        @user_api_integration.update(params_notifications)

        respond_to do |format|
          format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[edit_notifications] } }
          format.html { redirect_to integrations_slack_integration_path }
        end
      end

      private

      def params_notifications
        params.require(:user_api_integration).permit(:notifications_channel)
      end
    end
  end
end
