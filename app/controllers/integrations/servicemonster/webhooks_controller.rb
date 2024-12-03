# frozen_string_literal: true

# app/controllers/integrations/servicemonster/webhooks_controller.rb
module Integrations
  module Servicemonster
    # support for configuring actions on incoming webhooks from ServiceMonster
    class WebhooksController < Servicemonster::IntegrationsController
      before_action :webhook_event, only: %i[edit update]
      # (POST)
      # /integrations/servicemonster/webhooks
      # integrations_servicemonster_webhooks_path
      # integrations_servicemonster_webhooks_url
      def create
        create_new_webhook(params.permit(:id)&.dig(:id), webhook_params)

        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (DELETE)
      # /integrations/servicemonster/webhooks/:id
      # integrations_servicemonster_webhooks_path(:id)
      # integrations_servicemonster_webhooks_url(:id)
      def destroy
        destroy_webhook_event(params.permit(:id)&.dig(:id))

        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (GET)
      # /integrations/servicemonster/webhooks/:id/edit
      # edit_integrations_servicemonster_webhooks_path(:id)
      # edit_integrations_servicemonster_webhooks_url(:id)
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[webhooks_edit] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (GET)
      # /integrations/servicemonster/webhooks
      # integrations_servicemonster_webhooks_path
      # integrations_servicemonster_webhooks_url
      def index
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (GET)
      # /integrations/servicemonster/webhooks/new
      # new_integrations_servicemonster_webhooks_path
      # new_integrations_servicemonster_webhooks_url
      def new
        @webhook_event = {
          id:       SecureRandom.uuid,
          actions:  { tag_id: 0, group_id: 0, stage_id: 0, campaign_id: 0 },
          criteria: { account_subtypes: [], account_types: [], commercial: true, event_new: true, event_updated: true, job_types: [], line_items: [], order_type: '', range_max: 10_000, residential: true, total_max: 10_000, total_min: 0 }
        }

        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[webhooks_edit_new] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (PATCH/PUT) update webhooks
      # /integrations/servicemonster/webhooks/:id
      # integrations_servicemonster_webhook_path(:id)
      # integrations_servicemonster_webhook_url(:id)
      def update
        sanitized_params = webhook_params
        webhook_object   = Integration::Servicemonster.webhook_object_by_id(@client_api_integration.webhooks, @webhook_event.dig(:id))

        if webhook_object == sanitized_params.dig(:event).to_s
          provision_webhook(webhook_object)

          update_webhook(@webhook_event.dig(:id), sanitized_params)
          @client_api_integration.reload
        else
          destroy_webhook_event(@webhook_event.dig(:id))
          create_new_webhook(@webhook_event.dig(:id), sanitized_params)
        end

        @webhook_event = nil

        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      private

      def create_new_webhook(webhook_event_id, webhook_params)
        return unless webhook_event_id.present? && webhook_params.dig(:event).present? && webhook_params.dig(:actions).present?

        provision_webhook(webhook_params.dig(:event))

        @client_api_integration.webhooks[webhook_params.dig(:event).to_s]['events'] << {
          id:       webhook_event_id,
          actions:  webhook_params.dig(:actions),
          criteria: webhook_params.dig(:criteria)
        }
        @client_api_integration.save
      end

      def destroy_webhook_event(webhook_event_id)
        return if webhook_event_id.blank?
        return unless (webhook_event = Integration::Servicemonster.webhook_event_by_id(@client_api_integration.webhooks, webhook_event_id)) &&
                      (webhook = Integration::Servicemonster.webhook_by_event_id(@client_api_integration.webhooks, webhook_event_id))

        webhook_object = webhook.keys.first.to_s
        webhook_id     = webhook.values.first&.dig(:id)

        @client_api_integration.webhooks[webhook_object]&.dig('events')&.delete(webhook_event.deep_stringify_keys)
        @client_api_integration.webhooks.delete(webhook_object) if @client_api_integration.webhooks.dig(webhook_object)&.dig('events').blank?
        @client_api_integration.save

        return unless @client_api_integration.webhooks.keys.exclude?(webhook_object)
        return if webhook_id.blank?

        sm_client = Integrations::ServiceMonster.new(@client_api_integration.credentials)
        sm_client.deprovision_webhook(webhook_id)
      end

      def provision_webhook(webhook_object)
        return if (webhook = @client_api_integration.webhooks.dig(webhook_object)) &&
                  Integrations::ServiceMonster.new(@client_api_integration.credentials).webhook_active?(webhook&.dig('id'))

        sm_client = Integrations::ServiceMonster.new(@client_api_integration.credentials)
        sm_client.provision_webhook(event_object: webhook_object.to_s.split('_').first.downcase.sub('appointment', 'job'), event_type: webhook_object.to_s.split('_').last)

        if webhook
          webhook['id'] = sm_client.result.dig(:webhook_id).to_s
        else
          @client_api_integration.webhooks[webhook_object] = { 'id' => sm_client.result.dig(:webhook_id).to_s, 'events' => [] }
        end
      end

      def update_webhook(webhook_event_id, sanitized_params)
        return if webhook_event_id.blank?
        return unless (webhook_object = Integration::Servicemonster.webhook_object_by_id(@client_api_integration.webhooks, webhook_event_id)) &&
                      (webhook_event = @client_api_integration.webhooks.dig(webhook_object)&.dig('events')&.find { |e| e.dig('id') == webhook_event_id })

        webhook_event['id']         = webhook_event_id
        webhook_event['actions']    = sanitized_params.dig(:actions)
        webhook_event['criteria']   = sanitized_params.dig(:criteria)

        @client_api_integration.save
      end

      def webhook_event
        sanitized_params = params.permit(:id)

        return if sanitized_params.dig(:id).to_s.present? && (@webhook_event = Integration::Servicemonster.webhook_event_by_id(@client_api_integration.webhooks, sanitized_params.dig(:id)))

        sweetalert_error('Unknown Webhook!', 'The requested webhook was not found.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_servicemonster_path}'" and return false }
          format.html { redirect_to integrations_servicemonster_path and return false }
        end
      end

      def webhook_params
        sanitized_params = params.require(:webhook).permit(:event, criteria: [:appointment_status, :commercial, :event_new, :event_updated, :order_type, :order_type_voided, :range_max, :residential, :start_date_updated, :status_updated, :tech_updated, :total,
                                                                              { account_types: [], account_subtypes: [], ext_tech_ids: [], job_types: [], lead_sources: [], line_items: [], order_groups: [], order_subgroups: [] }],
                                                                   actions:  %i[assign_user_to_technician assign_user_to_salesrep campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])

        response_params  = { actions: {}, criteria: {}, event: sanitized_params.dig(:event).to_s }

        response_params[:actions] = {
          assign_user_to_technician: sanitized_params.dig(:actions, :assign_user_to_technician).to_bool,
          assign_user_to_salesrep:   sanitized_params.dig(:actions, :assign_user_to_salesrep).to_bool,
          campaign_id:               sanitized_params.dig(:actions, :campaign_id).to_i,
          group_id:                  sanitized_params.dig(:actions, :group_id).to_i,
          tag_id:                    sanitized_params.dig(:actions, :tag_id).to_i,
          stage_id:                  sanitized_params.dig(:actions, :stage_id).to_i,
          stop_campaign_ids:         sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
        }
        response_params[:actions][:stop_campaign_ids] = [0] if response_params[:actions][:stop_campaign_ids]&.include?('0')

        response_params[:criteria][:account_types]      = sanitized_params.dig(:criteria, :account_types)&.compact_blank || []
        response_params[:criteria][:account_subtypes]   = sanitized_params.dig(:criteria, :account_subtypes)&.compact_blank || []
        response_params[:criteria][:commercial]         = sanitized_params[:criteria][:commercial].to_bool if sanitized_params.dig(:criteria, :commercial)
        response_params[:criteria][:residential]        = sanitized_params[:criteria][:residential].to_bool if sanitized_params.dig(:criteria, :residential)

        case sanitized_params[:event].split('_').first
        when 'account'

          if %w[onupdated oninvoiced].include?(sanitized_params[:event].split('_').last.downcase)
            response_params[:criteria][:event_new]          = sanitized_params[:criteria][:event_new].to_bool if sanitized_params.dig(:criteria, :event_new)
            response_params[:criteria][:event_updated]      = sanitized_params[:criteria][:event_updated].to_bool if sanitized_params.dig(:criteria, :event_updated)
          end

          response_params[:criteria][:lead_sources]       = sanitized_params.dig(:criteria, :lead_sources)&.compact_blank&.map(&:to_i) || []
        when 'appointment'
          response_params[:criteria][:appointment_status] = sanitized_params.dig(:criteria, :appointment_status).to_s
          response_params[:criteria][:ext_tech_ids]       = sanitized_params.dig(:criteria, :ext_tech_ids)&.compact_blank || []
          response_params[:criteria][:job_types]          = sanitized_params.dig(:criteria, :job_types)&.compact_blank || []
          response_params[:criteria][:lead_sources]       = sanitized_params.dig(:criteria, :lead_sources)&.compact_blank&.map(&:to_i) || []
          response_params[:criteria][:line_items]         = sanitized_params.dig(:criteria, :line_items)&.compact_blank || []
          response_params[:criteria][:order_type]         = sanitized_params.dig(:criteria, :order_type).to_s
          response_params[:criteria][:range_max]          = sanitized_params[:criteria][:range_max].to_i if sanitized_params.dig(:criteria, :range_max)
          response_params[:criteria][:start_date_updated] = sanitized_params[:criteria][:start_date_updated].to_bool if sanitized_params.dig(:criteria, :start_date_updated)
          response_params[:criteria][:tech_updated]       = sanitized_params[:criteria][:tech_updated].to_bool if sanitized_params.dig(:criteria, :tech_updated)
          response_params[:criteria][:total_min]          = sanitized_params[:criteria][:total]&.split(';')&.first.to_i if sanitized_params.dig(:criteria, :total)
          response_params[:criteria][:total_max]          = sanitized_params[:criteria][:total]&.split(';')&.last.to_i if sanitized_params.dig(:criteria, :total)

          unless sanitized_params[:event].split('_').last.casecmp?('oncreated')
            response_params[:criteria][:event_new]          = sanitized_params[:criteria][:event_new].to_bool if sanitized_params.dig(:criteria, :event_new)
            response_params[:criteria][:event_updated]      = sanitized_params[:criteria][:event_updated].to_bool if sanitized_params.dig(:criteria, :event_updated)
            response_params[:criteria][:status_updated]     = sanitized_params[:criteria][:status_updated].to_bool if sanitized_params.dig(:criteria, :status_updated)
          end
        when 'order'
          response_params[:criteria][:lead_sources]       = sanitized_params.dig(:criteria, :lead_sources)&.compact_blank&.map(&:to_i) || []
          response_params[:criteria][:line_items]         = sanitized_params.dig(:criteria, :line_items)&.compact_blank || []
          response_params[:criteria][:order_groups]       = sanitized_params[:criteria][:order_groups]&.compact_blank || []
          response_params[:criteria][:order_subgroups]    = sanitized_params.dig(:criteria, :order_subgroups)&.compact_blank || []
          response_params[:criteria][:order_type]         = sanitized_params.dig(:criteria, :order_type).to_s unless sanitized_params[:event].split('_').last.casecmp?('oninvoiced')
          response_params[:criteria][:order_type_voided]  = sanitized_params.dig(:criteria, :order_type_voided).to_bool
          response_params[:criteria][:range_max]          = sanitized_params[:criteria][:range_max].to_i if sanitized_params.dig(:criteria, :range_max)
          response_params[:criteria][:total_min]          = sanitized_params[:criteria][:total]&.split(';')&.first.to_i if sanitized_params.dig(:criteria, :total)
          response_params[:criteria][:total_max]          = sanitized_params[:criteria][:total]&.split(';')&.last.to_i if sanitized_params.dig(:criteria, :total)

          if %w[onupdated oninvoiced].include?(sanitized_params[:event].split('_').last.downcase)
            response_params[:criteria][:event_new]          = sanitized_params[:criteria][:event_new].to_bool if sanitized_params.dig(:criteria, :event_new)
            response_params[:criteria][:event_updated]      = sanitized_params[:criteria][:event_updated].to_bool if sanitized_params.dig(:criteria, :event_updated)
          end
        end

        response_params
      end
    end
  end
end
