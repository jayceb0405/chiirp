# frozen_string_literal: true

# app/controllers/integrations/jobber/v20220915/webhooks_controller.rb
module Integrations
  module Jobber
    module V20220915
      # support for configuring actions on incoming webhooks from Jobber
      class WebhooksController < Jobber::V20220915::IntegrationsController
        # (POST)
        # /integrations/jobber/v20220915/webhooks
        # new_integrations_jobber_v20220915_webhook_path
        # new_integrations_jobber_v20220915_webhook_url
        def create
          create_new_webhook

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (DELETE)
        # /integrations/jobber/v20220915/webhooks/:id
        # integrations_jobber_v20220915_webhooks_path(:id)
        # integrations_jobber_v20220915_webhooks_url(:id)
        def destroy
          destroy_webhook

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (GET)
        # /integrations/jobber/v20220915/webhooks/:id/edit
        # edit_integrations_jobber_v20220915_webhook_path(:id)
        # edit_integrations_jobber_v20220915_webhook_url(:id)
        def edit
          @webhook = find_webhook_by_id(params.permit(:id).dig(:id))

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[webhooks_edit] }
        end

        # (GET)
        # /integrations/jobber/v20220915/webhooks
        # integrations_jobber_v20220915_webhooks_path
        # integrations_jobber_v20220915_webhooks_url
        def index
          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (GET)
        # /integrations/jobber/v20220915/webhooks/new
        # new_integrations_jobber_v20220915_webhooks_path
        # new_integrations_jobber_v20220915_webhooks_url
        def new
          event_id = create_new_event_id
          @client_api_integration.webhooks[''] = [{ 'actions' => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'campaign_id' => 0 }, 'criteria' => { 'event_new' => true, 'event_updated' => true }, 'event_id' => event_id }]
          @client_api_integration.save

          @webhook = find_webhook_by_id(event_id)

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[webhooks_index webhooks_open_new] }
        end

        # (PATCH/PUT) update webhooks
        # /integrations/jobber/v20220915/webhooks/:id
        # integrations_jobber_v20220915_webhook_path(:id)
        # integrations_jobber_v20220915_webhook_url(:id)
        def update
          destroy_webhook
          create_new_webhook

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[webhooks_index] }
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
          sanitized_params = params.require(:webhook).permit(:event, criteria: [:event_new, :event_updated, :start_date_updated, :tech_updated,
                                                                                { customer_type: [], ext_tech_ids: [], line_items: [], source: [], status: [], tag_ids_exclude: [], tag_ids_include: [] }],
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
          sanitized_params[:criteria][:event_new]          = sanitized_params.dig(:criteria, :event_new).to_bool
          sanitized_params[:criteria][:event_updated]      = sanitized_params.dig(:criteria, :event_updated).to_bool
          sanitized_params[:criteria][:ext_tech_ids]       = sanitized_params.dig(:criteria, :ext_tech_ids)&.compact_blank || []
          sanitized_params[:criteria][:line_items]         = sanitized_params.dig(:criteria, :line_items)&.compact_blank || []
          sanitized_params[:criteria][:source]             = sanitized_params.dig(:criteria, :source)&.compact_blank || []
          sanitized_params[:criteria][:start_date_updated] = sanitized_params.dig(:criteria, :start_date_updated).to_bool
          sanitized_params[:criteria][:status]             = sanitized_params.dig(:criteria, :status)&.compact_blank || []
          sanitized_params[:criteria][:tag_ids_exclude]    = sanitized_params.dig(:criteria, :tag_ids_exclude)&.compact_blank&.map(&:to_i) || []
          sanitized_params[:criteria][:tag_ids_include]    = sanitized_params.dig(:criteria, :tag_ids_include)&.compact_blank&.map(&:to_i) || []
          sanitized_params[:criteria][:tech_updated]       = sanitized_params.dig(:criteria, :tech_updated).to_bool

          sanitized_params
        end
      end
    end
  end
end
