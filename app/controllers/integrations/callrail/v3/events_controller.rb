# frozen_string_literal: true

module Integrations
  module Callrail
    module V3
      class EventsController < Integrations::Callrail::V3::IntegrationsController
        # (GET) CallRail events index
        # /integrations/callrail/v3/events
        # integrations_callrail_v3_events_path
        # integrations_callrail_v3_events_url
        def index
          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[events_index] }
        end

        # (GET) CallRail events screen
        # /integrations/callrail/v3/events/:id
        # integrations_callrail_v3_event_path
        # integrations_callrail_v3_event_url
        def show
          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[events_show] }
        end

        # (GET) CallRail events screen
        # /integrations/callrail/v3/events/:id/edit
        # new_integrations_callrail_v3_event_path
        # new_integrations_callrail_v3_event_url
        def new
          event_id = create_new_event_id
          @client_api_integration.events << event_defaults(event_id)
          @client_api_integration.save

          @event = find_event_by_id(event_id)

          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[events_index events_open_new] }
        end

        # (GET) CallRail events screen
        # /integrations/callrail/v3/events/:id/edit
        # edit_integrations_callrail_v3_event_path
        # edit_integrations_callrail_v3_event_url
        def edit
          @event = find_event_by_id(params[:id])
          cards = []

          if params.include?(:account_company_id)
            @event[:account_company_id] = params[:account_company_id]
            cards << 'events_edit_company'
          end

          if params.include?(:event_type)
            @event[:type] = params[:event_type]
            cards = %w[events_event_type_fields]
          end

          cards = %w[events_edit] if cards.empty?

          render partial: 'integrations/callrail/v3/js/show', locals: { cards: }
        end

        # (PUT/PATCH) CallRail events screen
        # /integrations/callrail/v3/events/:id
        # integrations_callrail_v3_event_path
        # integrations_callrail_v3_event_url
        def update
          update_event

          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[events_index] }
        end

        # (DELETE) CallRail events screen
        # /integrations/callrail/v3/events/:id
        # integrations_callrail_v3_event_path
        # integrations_callrail_v3_event_url
        def destroy
          destroy_event

          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[events_index] }
        end

        private

        def event_defaults(event_id)
          {
            event_id:,
            name:                   'New Event',
            account_company_id:     nil,
            type:                   '',
            call_types:             [],
            form_names:             [],
            tracking_phone_numbers: [],
            lead_statuses:          [],
            source_names:           [],
            include_tags:           [],
            exclude_tags:           [],
            keywords:               [],
            answered:               nil,
            action:                 {
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
          @event['account_company_id']              = sanitized_params[:account_company_id]
          @event['type']                            = sanitized_params[:type]
          @event['call_types']                      = sanitized_params[:call_types]
          @event['tracking_phone_numbers']          = sanitized_params[:tracking_phone_numbers]
          @event['source_names']                    = @event['tracking_phone_numbers'].present? ? [] : sanitized_params[:source_names]
          @event['lead_statuses']                   = sanitized_params[:lead_statuses]
          @event['include_tags']                    = sanitized_params[:include_tags]
          @event['exclude_tags']                    = sanitized_params[:exclude_tags]
          @event['keywords']                        = sanitized_params[:keywords]
          @event['form_names']                      = sanitized_params[:form_names]
          @event['answered']                        = sanitized_params[:answered] if @event['type'] == 'outbound_post_call'
          @event['action']                          = sanitized_params[:action]

          @client_api_integration.save
        end

        def event_params
          sanitized_params = params.require(:event).permit(:name, :account_company_id, :type, :keywords, :answered, form_names: [], source_names: [], tracking_phone_numbers: [], include_tags: [], exclude_tags: [], lead_statuses: [], call_types: [], action: %i[group_id stage_id campaign_id tag_id] + [{ stop_campaign_ids: [] }])

          sanitized_params[:name]                   = sanitized_params.dig(:name).strip
          sanitized_params[:account_company_id]     = sanitized_params.dig(:account_company_id).strip
          sanitized_params[:type]                   = sanitized_params.dig(:type)&.strip || 'inbound_post_call'
          sanitized_params[:call_types]             = sanitized_params.dig(:call_types)&.compact_blank
          sanitized_params[:tracking_phone_numbers] = sanitized_params.dig(:tracking_phone_numbers)&.map(&:clean_phone)&.compact_blank
          sanitized_params[:lead_statuses]          = sanitized_params.dig(:lead_statuses)&.compact_blank&.compact_blank
          sanitized_params[:source_names]           = sanitized_params.dig(:source_names)&.compact_blank
          sanitized_params[:include_tags]           = sanitized_params.dig(:include_tags)&.compact_blank
          sanitized_params[:exclude_tags]           = sanitized_params.dig(:exclude_tags)&.compact_blank
          sanitized_params[:form_names]             = sanitized_params.dig(:form_names)&.compact_blank
          sanitized_params[:keywords]               = sanitized_params.dig(:keywords)&.strip&.split(',')&.map(&:strip)&.compact_blank
          sanitized_params[:answered]               = sanitized_params.dig(:answered)&.strip == '' ? nil : sanitized_params.dig(:answered)&.strip&.to_bool
          sanitized_params[:action]                 = {
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
end
