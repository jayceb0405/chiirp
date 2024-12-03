# frozen_string_literal: true

# app/controllers/integrations/contractorcommerce/v1/webhooks_controller.rb
module Integrations
  module Contractorcommerce
    module V1
      # support for configuring actions on incoming webhooks from Contractor Commerce
      class EventsController < Contractorcommerce::IntegrationsController
        # (POST)
        # /integrations/contractorcommerce/v1/events
        # new_integraticns_Contractorcommerce_v1_events_path
        # new_integraticns_Contractorcommerce_v1_events_url
        def create
          create_new_event

          render partial: 'integrations/contractorcommerce/v1/js/show', locals: { cards: %w[webhooks_index] }
        end

        # (DELETE)
        # /integrations/contractorcommerce/v1/events/:id
        # integrations_contractorcommerce_v1_events_path(:id)
        # integrations_contractorcommerce_v1_events_url(:id)
        def destroy
          destroy_webhook
        end

        # (GET)
        # /integrations/contractorcommerce/v1/events/:id/edit
        # edit_integratcons_Contractorcommerce_v1_event_path(:id)
        # edit_integratcons_Contractorcommerce_v1_event_url(:id)
        def edit
          @event = find_event_by_id(params.permit(:id).dig(:id))
        end

        # (GET)
        # /integrations/contractorcommerce/v1/events
        # integrations_contractorcommerce_v1_events_path
        # integrations_contractorcommerce_v1_events_url
        def index; end

        # (GET)
        # /integrations/contractorcommerce/v1/events/new
        # new_integraticns_Contractorcommerce_v1_event_path
        # new_integraticns_Contractorcommerce_v1_event_url
        def new
          event_id = create_new_event_id
          @client_api_integration.events  = [] if @client_api_integration.events.blank?
          @client_api_integration.events << { event_id:, actions: { tag_id: 0, group_id: 0, stage_id: 0, campaign_id: 0, stop_campaign_ids: [] } }
          @client_api_integration.save

          @event = find_event_by_id(event_id)
        end

        # (PATCH/PUT) update webhooks
        # /integrations/contractorcommerce/v1/events/:id
        # integrations_contractorcommerce_v1_event_path(:id)
        # integrations_contractorcommerce_v1_event_url(:id)
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

          return if sanitized_params.dig(:actions).blank?

          @client_api_integration.events = [] if @client_api_integration.events.blank?
          @client_api_integration.events << {
            actions:  sanitized_params.dig(:actions),
            event_id: create_new_event_id
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
          sanitized_params = params.require(:event).permit(:event_id, actions: %i[assign_user campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

          sanitized_params[:actions] = {
            assign_user:       sanitized_params.dig(:actions, :assign_user).to_bool,
            campaign_id:       sanitized_params.dig(:actions, :campaign_id).to_i,
            group_id:          sanitized_params.dig(:actions, :group_id).to_i,
            stage_id:          sanitized_params.dig(:actions, :stage_id).to_i,
            tag_id:            sanitized_params.dig(:actions, :tag_id).to_i,
            stop_campaign_ids: sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
          }
          sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')

          sanitized_params
        end
      end
    end
  end
end
