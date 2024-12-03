# frozen_string_literal: true

# app/controllers/integrations/outreach/connections_controller.rb
module Integrations
  module Outreach
    # Support for all general Google integration endpoints used with Chiirp
    class ConnectionsController < Outreach::IntegrationsController
      # (DELETE) delete a Outreach connection
      # /integrations/outreach/connections
      # integrations_outreach_connections_path
      # integrations_outreach_connections_url
      def destroy
        # unsubscribe from all webhooks
        outreach_client = Integrations::OutReach.new(@client_api_integration.token, @client_api_integration.refresh_token, @client_api_integration.expires_at, current_user.client.tenant)

        @client_api_integration.webhook_actions.map(&:deep_symbolize_keys).each do |webhook|
          outreach_client.webhook_unsubscribe(webhook.dig(:id))
          @client_api_integration.webhook_actions.delete_if { |x| x['id'] == webhook.dig(:id) }
        end

        @client_api_integration.update(
          expires_at:    0,
          refresh_token: '',
          token:         ''
        )

        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[connections_edit] } }
          format.html { redirect_to integrations_outreach_integration_path }
        end
      end

      # (GET) Outreach integration configuration screen
      # /integrations/outreach/connections/edit
      # edit_integrations_outreach_connections_path
      # edit_integrations_outreach_connections_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[connections_edit] } }
          format.html { redirect_to integrations_outreach_integration_path }
        end
      end
    end
  end
end
