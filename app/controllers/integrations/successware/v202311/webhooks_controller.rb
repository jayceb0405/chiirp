# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/webhooks_controller.rb
module Integrations
  module Successware
    module V202311
      # support for configuring actions on incoming webhooks from Successware
      class WebhooksController < Successware::IntegrationsController
        # (POST)
        # /integrations/successware/v202311/webhooks
        # new_integrations_successware_v202311_webhook_path
        # new_integrations_successware_v202311_webhook_url
        def create
          create_new_webhook

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (DELETE)
        # /integrations/successware/v202311/webhooks/:id
        # integrations_successware_v202311_webhooks_path(:id)
        # integrations_successware_v202311_webhooks_url(:id)
        def destroy
          destroy_webhook

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (GET)
        # /integrations/successware/v202311/webhooks/:id/edit
        # edit_integrations_successware_v202311_webhook_path(:id)
        # edit_integrations_successware_v202311_webhook_url(:id)
        def edit
          @webhook = find_webhook_by_id(params.permit(:id).dig(:id))

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[webhooks_edit] }
        end

        # (GET)
        # /integrations/successware/v202311/webhooks
        # integrations_successware_v202311_webhooks_path
        # integrations_successware_v202311_webhooks_url
        def index
          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (GET)
        # /integrations/successware/v202311/webhooks/new
        # new_integrations_successware_v202311_webhooks_path
        # new_integrations_successware_v202311_webhooks_url
        def new
          event_id = create_new_event_id
          @client_api_integration.webhooks[''] = [{ 'actions' => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'campaign_id' => 0 }, 'criteria' => { 'event_new' => true, 'event_updated' => true }, 'event_id' => event_id }]
          @client_api_integration.save

          @webhook = find_webhook_by_id(event_id)

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[webhooks_index webhooks_open_new] }
        end

        # (GET) refresh Successware job types
        # /integrations/successware/v202311/webhooks/refresh_job_types/:id
        # integrations_successware_v202311_webhooks_refresh_job_types_path(:id)
        # integrations_successware_v202311_webhooks_refresh_job_types_url(:id)
        def refresh_job_types
          @webhook = find_webhook_by_id(params.permit(:id).dig(:id))
          Integration::Successware::V202311::Base.new(@client_api_integration).refresh_job_types
        end

        # (PATCH/PUT) update webhooks
        # /integrations/successware/v202311/webhooks/:id
        # integrations_successware_v202311_webhook_path(:id)
        # integrations_successware_v202311_webhook_url(:id)
        def update
          destroy_webhook
          create_new_webhook

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[webhooks_index] }
        end

        private

        def create_new_event_id
          event_id = RandomCode.new.create(20)
          event_id = RandomCode.new.create(20) while @client_api_integration.webhooks.map { |_k, v| v.map { |e| e.dig('event_id') } }.flatten.include?(event_id)
          event_id
        end

        def create_new_webhook
          sanitized_params = webhook_params

          return unless sanitized_params.dig(:event).present? && sanitized_params.dig(:actions).present? && sanitized_params.dig(:criteria).present?

          @client_api_integration.webhooks[sanitized_params.dig(:event)] = [] unless @client_api_integration.webhooks&.dig(sanitized_params.dig(:event))
          @client_api_integration.webhooks[sanitized_params.dig(:event)] << {
            actions:  sanitized_params.dig(:actions),
            criteria: sanitized_params.dig(:criteria),
            event_id: create_new_event_id
          }

          @client_api_integration.save
        end

        def destroy_webhook
          sanitized_params = params.permit(:id, :event)

          return if sanitized_params.dig(:id).blank?

          @client_api_integration.webhooks[sanitized_params.dig(:event).to_s].delete_if { |x| x['event_id'] == sanitized_params.dig(:id).to_s }
          @client_api_integration.save
        end

        def find_webhook_by_id(webhook_id)
          [find_webhook_event_by_id(webhook_id).first, find_webhook_event_by_id(webhook_id).second.find { |w| w.dig('event_id') == webhook_id }]
        end

        def find_webhook_event_by_id(webhook_id)
          @client_api_integration.webhooks.find { |_k, v| v.find { |e| e.dig('event_id') == webhook_id } } || []
        end

        def webhook_params
          sanitized_params = params.require(:webhook).permit(:event, criteria: [:start_date_updated, :tech_updated,
                                                                                { customer_type: [], ext_tech_ids: [], job_type: [] }],
                                                                     actions:  %i[assign_user campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

          sanitized_params[:actions] = {
            assign_user:       sanitized_params.dig(:actions, :assign_user).to_bool,
            campaign_id:       sanitized_params.dig(:actions, :campaign_id).to_i,
            group_id:          sanitized_params.dig(:actions, :group_id).to_i,
            stage_id:          sanitized_params.dig(:actions, :stage_id).to_i,
            tag_id:            sanitized_params.dig(:actions, :tag_id).to_i,
            stop_campaign_ids: sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
          }
          sanitized_params[:actions][:stop_campaign_ids]   = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')
          sanitized_params[:criteria][:customer_type]      = sanitized_params.dig(:criteria, :customer_type)&.compact_blank || []
          sanitized_params[:criteria][:job_type]           = sanitized_params.dig(:criteria, :job_type)&.compact_blank || []
          sanitized_params[:criteria][:ext_tech_ids]       = sanitized_params.dig(:criteria, :ext_tech_ids)&.compact_blank || []
          sanitized_params[:criteria][:start_date_updated] = sanitized_params.dig(:criteria, :start_date_updated).to_bool
          sanitized_params[:criteria][:tech_updated]       = sanitized_params.dig(:criteria, :tech_updated).to_bool

          sanitized_params
        end
      end
    end
  end
end
