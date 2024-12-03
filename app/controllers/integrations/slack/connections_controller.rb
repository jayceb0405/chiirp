# frozen_string_literal: true

# app/controllers/integrations/slack/connections_controller.rb
module Integrations
  module Slack
    class ConnectionsController < Slack::IntegrationsController
      # (DELETE) revoke a User's Permissions
      # /integrations/slack/connections
      # integrations_slack_connections_path
      # integrations_slack_connections_url
      def destroy
        slack_client = Integrations::Slacker::Base.new(@user_api_integration.token)
        slack_client.oauth_revoke

        @user_api_integration.update(token: '', notifications_channel: '')

        respond_to do |format|
          format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[edit_connections] } }
          format.html { redirect_to integrations_slack_integration_path }
        end
      end

      # (GET) Slack integration configuration screen
      # /integrations/slack/connections/edit
      # edit_integrations_slack_connections_path
      # edit_integrations_slack_connections_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[edit_connections] } }
          format.html { redirect_to integrations_slack_integration_path }
        end
      end

      # DEPRECATED (or maybe never used?)
      # (PATCH/PUT) subscribe/unsubscribe to Slack Leads for a page
      # /integrations/slack/connections
      # integrations_slack_connections_path
      # integrations_slack_connections_url
      # def update
      #   page_id   = params.dig(:page_id).to_s
      #   subscribe = params.dig(:subscribe).to_bool

      #   if page_id.present? && (page = @user_api_integration.pages.find { |p| p['id'] == page_id })

      #     if subscribe
      #       Integrations::FaceBook::Base.new.page_subscribe(page_token: page['token'], page_id: page['id'])
      #     else
      #       Integrations::FaceBook::Base.new.page_unsubscribe(page_token: page['token'], page_id: page['id'])
      #     end
      #   end

      #   respond_to do |format|
      #     format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[edit_connections] } }
      #     format.html { redirect_to integrations_slack_integration_path }
      #   end
      # end
    end
  end
end
