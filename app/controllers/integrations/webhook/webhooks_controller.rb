# frozen_string_literal: true

# app/controllers/integrations/webhook/webhooks_controller.rb
module Integrations
  module Webhook
    class WebhooksController < Webhook::IntegrationsController
      # Sample ClientApiIntegration.webhooks
      # {
      #   '(UUID)' => {
      #     'type'   => '(String)',
      #     'url'    => '(String)',
      #     'fields' => [Array]
      #   }
      # }

      # (POST)
      # /integrations/webhook/webhooks
      # integrations_webhook_webhooks_path
      # integrations_webhook_webhooks_url
      def create
        @client_api_integration.webhooks[params_webhook_id.dig(:webhook_id)] = params_webhook
        @client_api_integration.save

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (DELETE) update webhooks
      # /integrations/webhook/webhooks/:id
      # integrations_webhook_webhook_path(:id)
      # integrations_webhook_webhook_url(:id)
      def destroy
        @client_api_integration.webhooks.delete(params_webhook_id.dig(:webhook_id))
        @client_api_integration.save

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (GET)
      # /integrations/webhook/webhooks/:id/edit
      # edit_integrations_webhook_webhook_path(:id)
      # edit_integrations_webhook_webhook_url(:id)
      def edit
        @webhook_id = params_webhook_id.dig(:webhook_id)

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[webhooks_edit] }
      end

      # (POST)
      # /integrations/webhook/webhooks
      # integrations_webhook_webhooks_path
      # integrations_webhook_webhooks_url
      def index
        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (GET)
      # /integrations/webhook/webhooks/new
      # new_integrations_webhook_webhook_path
      # new_integrations_webhook_webhook_url
      def new
        @webhook_id = SecureRandom.uuid
        @client_api_integration.webhooks = { @webhook_id => {} }.merge(@client_api_integration.webhooks)

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[webhooks_index webhooks_open webhooks_edit] }
      end

      # (PATCH/PUT)
      # /integrations/webhook/webhooks/:id
      # integrations_webhook_webhook_path(:id)
      # integrations_webhook_webhook_url(:id)
      def update
        @client_api_integration.webhooks[params_webhook_id.dig(:webhook_id)] = params_webhook
        @client_api_integration.save

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[webhooks_index] }
      end

      private

      def params_webhook
        sanitized_params = params.permit(:type, :url, fields: [])
        sanitized_params[:fields] = sanitized_params.dig(:fields).compact_blank

        sanitized_params
      end

      def params_webhook_id
        { webhook_id: params.permit(:webhook_id).dig(:webhook_id) || params.permit(:id).dig(:id) }
      end
    end
  end
end
