# frozen_string_literal: true

# app/controllers/integrations/thumbtack/v2/webhooks_controller.rb
module Integrations
  module Thumbtack
    module V2
      # support for configuring actions on incoming webhooks from Thumbtack
      class EventsController < Thumbtack::IntegrationsController
        # (POST)
        # /integrations/thumbtack/v2/events
        # new_integrations_thumbtack_v2_events_path
        # new_integrations_thumbtack_v2_events_url
        def create
          create_new_event

          render partial: 'integrations/thumbtack/v2/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (DELETE)
        # /integrations/thumbtack/v2/events/:id
        # integrations_thumbtack_v2_events_path(:id)
        # integrations_thumbtack_v2_events_url(:id)
        def destroy
          destroy_webhook
        end

        # (GET)
        # /integrations/thumbtack/v2/events/:id/edit
        # edit_integrations_thumbtack_v2_event_path(:id)
        # edit_integrations_thumbtack_v2_event_url(:id)
        def edit
          @event = find_event_by_id(params.permit(:id).dig(:id))
        end

        # (GET)
        # /integrations/thumbtack/v2/events
        # integrations_thumbtack_v2_events_path
        # integrations_thumbtack_v2_events_url
        def index; end

        # (GET)
        # /integrations/thumbtack/v2/events/new
        # new_integrations_thumbtack_v2_event_path
        # new_integrations_thumbtack_v2_event_url
        def new
          event_id = create_new_event_id
          @client_api_integration.events  = [] if @client_api_integration.events.blank?
          @client_api_integration.events << { event_id:, name: 'New Event', event_type: 'lead', actions: { tag_id: 0, group_id: 0, stage_id: 0, campaign_id: 0, stop_campaign_ids: [] }, criteria: { event_new: true, event_updated: true } }
          @client_api_integration.save

          @event = find_event_by_id(event_id)
        end

        # (PATCH/PUT) update webhooks
        # /integrations/thumbtack/v2/events/:id
        # integrations_thumbtack_v2_event_path(:id)
        # integrations_thumbtack_v2_event_url(:id)
        def update
          destroy_webhook
          create_new_event
        end

        private

        def create_new_event_id
          event_id = SecureRandom.uuid
          event_id = SecureRandom.uuid while @client_api_integration.events&.map { |e| e.dig('event_id') }&.include?(event_id)
          event_id
        end

        def create_new_event
          sanitized_params = event_params

          return unless sanitized_params.dig(:event_type).present? && sanitized_params.dig(:actions).present? && sanitized_params.dig(:criteria).present?

          @client_api_integration.events = [] if @client_api_integration.events.blank?
          @client_api_integration.events << {
            actions:    sanitized_params.dig(:actions),
            criteria:   sanitized_params.dig(:criteria),
            event_id:   create_new_event_id,
            name:       sanitized_params.dig(:name),
            event_type: sanitized_params.dig(:event_type)
          }

          @client_api_integration.save
        end

        def destroy_webhook
          sanitized_params = params.permit(:id, :event)

          return if sanitized_params.dig(:id).blank?

          @client_api_integration.events.delete_if { |x| x['event_id'] == sanitized_params.dig(:id).to_s }
          @client_api_integration.save
        end

        def find_event_by_id(event_id)
          (@client_api_integration.events.find { |e| e.dig('event_id') == event_id } || {}).deep_symbolize_keys
        end

        def event_params
          sanitized_params = params.require(:event).permit(:event_type, :name, criteria: [:event_new, :event_updated, :start_date_updated, :tech_updated,
                                                                                          { lead_types: [], customer_type: [], ext_tech_ids: [], line_items: [], source: [], status: [], tag_ids_exclude: [], tag_ids_include: [] }],
                                                                               actions:  %i[assign_user campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

          sanitized_params[:actions] = {
            assign_user:       sanitized_params.dig(:actions, :assign_user).to_bool,
            campaign_id:       sanitized_params.dig(:actions, :campaign_id).to_i,
            group_id:          sanitized_params.dig(:actions, :group_id).to_i,
            stage_id:          sanitized_params.dig(:actions, :stage_id).to_i,
            tag_id:            sanitized_params.dig(:actions, :tag_id).to_i,
            stop_campaign_ids: sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
          }
          sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')
          sanitized_params[:criteria][:lead_types] = sanitized_params.dig(:criteria, :lead_types)&.compact_blank || []

          sanitized_params
        end
      end
    end
  end
end
