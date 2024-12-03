# frozen_string_literal: true

module Integrations
  module Cardx
    class EventsController < Integrations::Cardx::IntegrationsController
      # (GET) CardX events index
      # /integrations/cardx/events
      # integrations_cardx_v3_events_path
      # integrations_cardx_v3_events_url
      def index
        render partial: 'integrations/cardx/js/show', locals: { cards: %w[events_index] }
      end

      # (GET) CardX events screen
      # /integrations/cardx/events/:id
      # integrations_cardx_v3_event_path
      # integrations_cardx_v3_event_url
      def show
        render partial: 'integrations/cardx/js/show', locals: { cards: %w[events_show] }
      end

      # (GET) CardX events screen
      # /integrations/cardx/events/:id/edit
      # new_integrations_cardx_v3_event_path
      # new_integrations_cardx_v3_event_url
      def new
        event_id = create_new_event_id
        @client_api_integration.events << event_defaults(event_id)
        @client_api_integration.save

        @event = find_event_by_id(event_id)

        render partial: 'integrations/cardx/js/show', locals: { cards: %w[events_index events_open_new] }
      end

      # (GET) CardX events screen
      # /integrations/cardx/events/:id/edit
      # edit_integrations_cardx_v3_event_path
      # edit_integrations_cardx_v3_event_url
      def edit
        @event = find_event_by_id(params[:id])
        @event[:account_company_id] = params[:account_company_id] if params.include?(:account_company_id)
        cards = params.include?(:account_company_id) ? %w[events_edit_company] : %w[events_edit]

        render partial: 'integrations/cardx/js/show', locals: { cards: }
      end

      # (PUT/PATCH) CardX events screen
      # /integrations/cardx/events/:id
      # integrations_cardx_v3_event_path
      # integrations_cardx_v3_event_url
      def update
        update_event

        render partial: 'integrations/cardx/js/show', locals: { cards: %w[events_index] }
      end

      # (DELETE) CardX events screen
      # /integrations/cardx/events/:id
      # integrations_cardx_v3_event_path
      # integrations_cardx_v3_event_url
      def destroy
        destroy_event

        render partial: 'integrations/cardx/js/show', locals: { cards: %w[events_index] }
      end

      private

      def event_defaults(event_id)
        {
          event_id:,
          name:                       'New Event',
          remaining_balance_operator: '',
          remaining_balance:          0.0,
          action:                     {
            campaign_id: nil,
            group_id:    nil,
            tag_id:      nil,
            stage_id:    nil
          }
        }
      end

      def create_new_event_id
        event_id = RandomCode.new.create(20)
        event_id = RandomCode.new.create(20) while @client_api_integration.events.pluck('event_id').include?(event_id)
        event_id
      end

      def find_event_by_id(event_id)
        @client_api_integration.events.find { |v| v['event_id'] == event_id } || {}
      end

      def destroy_event
        sanitized_params = params.permit(:id)

        return if sanitized_params.dig(:id).blank?

        @client_api_integration.events.delete_if { |x| x['event_id'] == sanitized_params.dig(:id).to_s }
        @client_api_integration.save
      end

      def update_event
        sanitized_params = event_params
        @event = find_event_by_id(params[:id])

        return if sanitized_params.blank?

        @event['name']                            = sanitized_params[:name]
        @event['remaining_balance_operator']      = sanitized_params[:remaining_balance_operator]
        @event['remaining_balance']               = sanitized_params[:remaining_balance]
        @event['gateway_accounts']                = sanitized_params[:gateway_accounts]
        @event['action']                          = sanitized_params[:action]

        @client_api_integration.save
      end

      def event_params
        sanitized_params = params.require(:event).permit(:name, :remaining_balance, :remaining_balance_operator, action: %i[group_id stage_id campaign_id tag_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:name]                       = sanitized_params.dig(:name).strip
        sanitized_params[:remaining_balance_operator] = case sanitized_params[:remaining_balance_operator]
                                                        when 'lte', 'gte'
                                                          sanitized_params[:remaining_balance_operator]
                                                        end
        sanitized_params[:remaining_balance]          = sanitized_params[:remaining_balance_operator].present? ? sanitized_params.dig(:remaining_balance).strip.to_f : 0.0
        sanitized_params[:action] = {
          tag_id:            sanitized_params[:action][:tag_id].to_i.zero? ? nil : sanitized_params[:action][:tag_id].to_i,
          group_id:          sanitized_params[:action][:group_id].to_i.zero? ? nil : sanitized_params[:action][:group_id].to_i,
          stage_id:          sanitized_params[:action][:stage_id].to_i.zero? ? nil : sanitized_params[:action][:stage_id].to_i,
          campaign_id:       sanitized_params[:action][:campaign_id].to_i.zero? ? nil : sanitized_params[:action][:campaign_id].to_i,
          stop_campaign_ids: sanitized_params[:action][:stop_campaign_ids].nil? ? [] : sanitized_params[:action][:stop_campaign_ids].compact_blank
        }
        sanitized_params[:action][:stop_campaign_ids] = [0] if sanitized_params[:action][:stop_campaign_ids].include?('0')

        sanitized_params
      end
    end
  end
end
