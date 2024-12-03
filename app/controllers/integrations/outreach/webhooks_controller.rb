# frozen_string_literal: true

# app/controllers/integrations/outreach/webhooks_controller.rb
module Integrations
  module Outreach
    # support for configuring actions on incoming webhooks from Outreach
    class WebhooksController < Outreach::IntegrationsController
      # (POST)
      # /integrations/outreach/webhooks
      # integrations_outreach_webhooks_path
      # integrations_outreach_webhooks_url
      def create
        create_new_webhook

        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_outreach_path }
        end
      end

      # (DELETE)
      # /integrations/outreach/webhooks/:id
      # integrations_outreach_webhooks_path(:id)
      # integrations_outreach_webhooks_url(:id)
      def destroy
        destroy_webhook

        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_outreach_path }
        end
      end

      # (GET)
      # /integrations/outreach/webhooks/:id/edit
      # edit_integrations_outreach_webhook_path(:id)
      # edit_integrations_outreach_webhook_url(:id)
      def edit
        webhook_id = params.permit(:id).dig(:id)

        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[webhooks_edit], webhook_id: } }
          format.html { redirect_to integrations_outreach_path }
        end
      end

      # (GET)
      # /integrations/outreach/webhooks
      # integrations_outreach_webhooks_path
      # integrations_outreach_webhooks_url
      def index
        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_outreach_path }
        end
      end

      # (GET)
      # /integrations/outreach/webhooks/new
      # new_integrations_outreach_webhook_path
      # new_integrations_outreach_webhook_url
      def new
        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[webhooks_index webhooks_open_new] } }
          format.html { redirect_to integrations_outreach_path }
        end
      end

      # (PATCH/PUT) update webhooks
      # /integrations/outreach/webhooks/:id
      # integrations_outreach_webhook_path(:id)
      # integrations_outreach_webhook_url(:id)
      def update
        destroy_webhook
        create_new_webhook

        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_outreach_path }
        end
      end

      private

      def create_new_webhook
        sanitized_params = webhook_params

        return unless sanitized_params.dig(:resource).to_s.present? && sanitized_params.dig(:actions).present?

        outreach_client = Integrations::OutReach.new(@client_api_integration.token, @client_api_integration.refresh_token, @client_api_integration.expires_at, current_user.client.tenant)
        outreach_client.webhook_subscribe(current_user.client_id, sanitized_params.dig(:resource).to_s, sanitized_params.dig(:action).to_s, @client_api_integration.api_key)

        return unless outreach_client.success?

        sanitized_params[:id] = outreach_client.result.dig(:id).to_i
        @client_api_integration.webhook_actions << sanitized_params
        @client_api_integration.save
      end

      def destroy_webhook
        id = params.permit(:webhook, :id).dig(:id).to_i

        return if id.zero?

        outreach_client = Integrations::OutReach.new(@client_api_integration.token, @client_api_integration.refresh_token, @client_api_integration.expires_at, current_user.client.tenant)
        outreach_client.webhook_unsubscribe(id)

        return unless outreach_client.success?

        @client_api_integration.webhook_actions.delete_if { |x| x['id'] == id }
        @client_api_integration.save
      end

      def webhook_params
        sanitized_params = params.require(:webhook).permit(:id, :resource_action, :call_disposition_id, actions: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:resource]            = sanitized_params.dig(:resource_action).to_s.split('_')[0]
        sanitized_params[:action]              = sanitized_params.dig(:resource_action).to_s.split('_')[1]
        sanitized_params[:call_disposition_id] = sanitized_params[:call_disposition_id].to_i if sanitized_params.include?(:call_disposition_id)
        sanitized_params[:actions]             = {
          campaign_id:       sanitized_params.dig(:actions, :campaign_id).to_i,
          group_id:          sanitized_params.dig(:actions, :group_id).to_i,
          tag_id:            sanitized_params.dig(:actions, :tag_id).to_i,
          stage_id:          sanitized_params.dig(:actions, :stage_id).to_i,
          stop_campaign_ids: sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
        }
        sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params[:actions][:stop_campaign_ids]&.include?('0')
        sanitized_params.delete(:resource_action)

        sanitized_params
      end
    end
  end
end
