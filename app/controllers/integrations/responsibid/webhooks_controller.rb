# frozen_string_literal: true

# app/controllers/integrations/responsibid/webhooks_controller.rb
module Integrations
  module Responsibid
    # support for configuring actions on incoming webhooks from ResponsiBid
    class WebhooksController < Responsibid::IntegrationsController
      before_action :webhook_event, only: %i[edit]
      # (POST)
      # /integrations/responsibid/webhooks
      # integrations_responsibid_webhooks_path
      # integrations_responsibid_webhooks_url
      def create
        create_new_webhook

        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[webhooks_created] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end

      # (DELETE)
      # /integrations/responsibid/webhooks/:id
      # integrations_responsibid_webhooks_path(:id)
      # integrations_responsibid_webhooks_url(:id)
      def destroy
        webhook_event_id = params.permit(:id).dig(:id).to_s

        destroy_webhook(webhook_event_id)

        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end

      # (GET)
      # /integrations/responsibid/webhooks/:id/edit
      # edit_integrations_responsibid_webhooks_path(:id)
      # edit_integrations_responsibid_webhooks_url(:id)
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[webhooks_edit] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end

      # (GET)
      # /integrations/responsibid/webhooks
      # integrations_responsibid_webhooks_path
      # integrations_responsibid_webhooks_url
      def index
        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end

      # (GET)
      # /integrations/responsibid/webhooks/new
      # new_integrations_responsibid_webhooks_path
      # new_integrations_responsibid_webhooks_url
      def new
        @webhook_event = { 'actions' => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'campaign_id' => 0 }, 'event_id' => '', 'version' => 2 }

        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[webhooks_index webhooks_open_new] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end

      # (PATCH/PUT) update webhooks
      # /integrations/responsibid/webhooks/:id
      # integrations_responsibid_webhook_path(:id)
      # integrations_responsibid_webhook_url(:id)
      def update
        sanitized_params = webhook_params
        webhook_event_id = params.permit(:id).dig(:id).to_s

        if Integration::Responsibid.webhook_object_by_id(@client_api_integration.webhooks, webhook_event_id) == sanitized_params.dig(:event).to_s
          update_webhook(webhook_event_id, sanitized_params)
          @client_api_integration.reload
          cards = %w[webhooks_edit]
        else
          destroy_webhook(webhook_event_id)
          create_new_webhook
          cards = %w[webhooks_index]
        end

        @webhook_event = Integration::Responsibid.webhook_event_by_id(@client_api_integration.webhooks, webhook_event_id)

        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end

      private

      def create_new_webhook
        sanitized_params = webhook_params

        return unless sanitized_params.dig(:event).present? && sanitized_params.dig(:actions).present?

        event_id = SecureRandom.uuid

        criteria = {}
        criteria['event_new']        = sanitized_params.dig(:event_new).to_bool
        criteria['event_updated']    = sanitized_params.dig(:event_updated).to_bool

        @client_api_integration.webhooks[sanitized_params.dig(:event).to_s] = [] unless @client_api_integration.webhooks.dig(sanitized_params.dig(:event).to_s)
        @client_api_integration.webhooks[sanitized_params.dig(:event).to_s] << {
          event_id:,
          criteria:,
          actions:  sanitized_params.dig(:actions),
          version:  sanitized_params.dig(:version)
        }
        @client_api_integration.save
        @webhook_event = Integration::Responsibid.webhook_event_by_id(@client_api_integration.webhooks, event_id)
      end

      def destroy_webhook(id)
        return if id.to_s.blank?

        return unless (webhook_event = Integration::Responsibid.webhook_event_by_id(@client_api_integration.webhooks, id)) &&
                      (webhook = Integration::Responsibid.webhook_by_id(@client_api_integration.webhooks, id))

        @client_api_integration.webhooks[webhook.keys.first.to_s].delete(webhook_event.deep_stringify_keys)
        @client_api_integration.webhooks.compact_blank
        @client_api_integration.save
      end

      def webhook_event
        sanitized_params = params.permit(:id)

        return if sanitized_params.dig(:id).to_s.present? && (@webhook_event = Integration::Responsibid.webhook_event_by_id(@client_api_integration.webhooks, sanitized_params.dig(:id)))

        sweetalert_error('Unknown Webhook!', 'The requested webhook was not found.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_responsibid_path}'" and return false }
          format.html { redirect_to integrations_responsibid_path and return false }
        end
      end

      def update_webhook(webhook_event_id, sanitized_params)
        webhook_object = Integration::Responsibid.webhook_object_by_id(@client_api_integration.webhooks, webhook_event_id)

        return unless webhook_event_id.present? && (webhook = @client_api_integration.webhooks.dig(webhook_object)&.find { |w| w.dig('event_id') == webhook_event_id })

        webhook['criteria']['event_new']        = sanitized_params.dig(:event_new).to_bool
        webhook['criteria']['event_updated']    = sanitized_params.dig(:event_updated).to_bool
        webhook['actions']                      = sanitized_params.dig(:actions)

        @client_api_integration.save
      end

      def webhook_params
        sanitized_params = params.require(:webhook).permit(:event, :event_id, :event_new, :event_updated, :version, actions: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:actions] = {
          campaign_id:       sanitized_params.dig(:actions, :campaign_id).to_i,
          group_id:          sanitized_params.dig(:actions, :group_id).to_i,
          tag_id:            sanitized_params.dig(:actions, :tag_id).to_i,
          stage_id:          sanitized_params.dig(:actions, :stage_id).to_i,
          stop_campaign_ids: sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
        }
        sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params[:actions][:stop_campaign_ids]&.include?('0')
        sanitized_params[:event_new]                   = sanitized_params.dig(:event_new).to_bool
        sanitized_params[:event_updated]               = sanitized_params.dig(:event_updated).to_bool
        sanitized_params[:version]                     = sanitized_params.dig(:version).to_i

        sanitized_params
      end
    end
  end
end
