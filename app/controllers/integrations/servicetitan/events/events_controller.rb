# frozen_string_literal: true

# app/controllers/integrations/servicetitan/events/events_controller.rb
module Integrations
  module Servicetitan
    module Events
      class EventsController < Servicetitan::EventsController
        # (DELETE) delete a JobComplete estimate action
        # /integrations/servicetitan/events/events/:id
        # integrations_servicetitan_events_event_path(:id)
        # integrations_servicetitan_events_event_url(:id)
        def destroy
          if params.dig(:id).to_i.positive?
            @client_api_integration.events.delete(params[:id].to_s)
            @client_api_integration.save
          end

          initialize_event_cookie
        end

        # (GET) show ServiceTitan events form
        # /integrations/servicetitan/events/events/:id/edit
        # edit_integrations_servicetitan_events_event_path(:id)
        # edit_integrations_servicetitan_events_event_url(:id)
        def edit
          @event_id = params.dig(:id)

          update_event_cookie(@event_id)
        end

        # (GET) list ServiceTitan events
        # /integrations/servicetitan/events/events
        # integrations_servicetitan_events_events_path
        # integrations_servicetitan_events_events_url
        def index
          # initialize_event_cookie
        end

        # (GET) initialize a new ServiceTitan action
        # /integrations/servicetitan/events/events/new
        # new_integrations_servicetitan_events_event_path
        # new_integrations_servicetitan_events_event_url
        # new_integrations_servicetitan_events_path
        # new_integrations_servicetitan_events_url
        def new
          @client_api_integration.events['0'] = { 'action_type' => '', 'call_duration' => 60, 'customer_type' => [], 'status' => '', 'job_types' => [], 'business_unit_ids' => [], 'membership' => [], 'total_min' => 0, 'total_max' => 0, 'range_max' => 1_000, 'campaign_id' => 0, 'group_id' => 0, 'tag_id' => 0, 'stage_id' => 0 }
          @event_id = '0'

          update_event_cookie(@event_id)
        end

        # (PUT/PATCH) update JobComplete actions
        # /integrations/servicetitan/events/events/:id
        # integrations_servicetitan_events_event_path(:id)
        # integrations_servicetitan_events_event_url(:id)
        def update
          @client_api_integration.update(events: params_update_events)

          initialize_event_cookie
        end

        private

        def params_update_events
          response = @client_api_integration.events
          sanitized_params = params.require(:events).permit(:action_type, :assign_contact_to_user, :call_duration, :campaign_id, :group_id, :id, :membership_days_prior, :orphaned_estimates, :range_max, :stage_id, :start_date_changes_only, :status, :tag_id, :total, business_unit_ids: [], call_directions: [], call_reason_ids: [], call_types: [], campaign_ids: [], campaign_name: %i[contains end segment start], customer_type: [], ext_tech_ids: [], job_cancel_reason_ids: [], job_types: [], membership_campaign_stop_statuses: [], membership_types: [], membership_types_stop: [], membership: [], new_status: [], stop_campaign_ids: [], tag_ids_exclude: [], tag_ids_include: [], st_customer: %i[yes no])

          if sanitized_params.dig(:id).to_i.positive?
            id = sanitized_params[:id].to_i
          else
            id = rand(1..10_000) while response.keys.map(&:to_i).include?(id) || id.nil?
          end

          sanitized_params[:stop_campaign_ids] = [0] if sanitized_params[:stop_campaign_ids]&.include?('0') # no need to keep other ids

          response[id] = {
            action_type:                       sanitized_params.dig(:action_type).to_s,
            assign_contact_to_user:            sanitized_params.dig(:assign_contact_to_user).to_bool,
            business_unit_ids:                 sanitized_params.dig(:business_unit_ids).compact_blank.map(&:to_i),
            call_directions:                   sanitized_params.dig(:call_directions).compact_blank,
            call_duration_from:                sanitized_params.dig(:call_duration).to_s.split(';')[0].to_i,
            call_duration_to:                  sanitized_params.dig(:call_duration).to_s.split(';')[1].to_i,
            call_reason_ids:                   (sanitized_params.dig(:call_reason_ids).presence || []).compact_blank.map(&:to_i),
            call_types:                        sanitized_params.dig(:call_types).compact_blank,
            campaign_id:                       sanitized_params.dig(:campaign_id).to_i,
            campaign_ids:                      (sanitized_params.dig(:campaign_ids).presence || []).compact_blank.map(&:to_i),
            campaign_name:                     {
              contains: sanitized_params.dig(:campaign_name, :contains).to_bool,
              end:      sanitized_params.dig(:campaign_name, :end).to_bool,
              segment:  sanitized_params.dig(:campaign_name, :segment).to_s.strip,
              start:    sanitized_params.dig(:campaign_name, :start).to_bool
            },
            customer_type:                     sanitized_params.dig(:customer_type).compact_blank,
            ext_tech_ids:                      sanitized_params.dig(:ext_tech_ids).compact_blank.map(&:to_i),
            group_id:                          sanitized_params.dig(:group_id).to_i,
            job_cancel_reason_ids:             (sanitized_params.dig(:job_cancel_reason_ids).presence || []).compact_blank.map(&:to_i),
            job_types:                         sanitized_params.dig(:job_types).compact_blank.map(&:to_i),
            membership:                        sanitized_params.dig(:membership).compact_blank,
            membership_campaign_stop_statuses: sanitized_params.dig(:membership_campaign_stop_statuses).compact_blank.map(&:to_s),
            membership_days_prior:             sanitized_params.dig(:membership_days_prior).to_i,
            membership_types:                  sanitized_params.dig(:membership_types).compact_blank.map(&:to_i),
            membership_types_stop:             sanitized_params.dig(:membership_types_stop).compact_blank.map(&:to_i),
            new_status:                        sanitized_params.dig(:new_status).compact_blank,
            orphaned_estimates:                sanitized_params.dig(:orphaned_estimates).to_bool,
            range_max:                         sanitized_params.dig(:range_max).to_i,
            st_customer:                       { yes: sanitized_params.dig(:st_customer, :yes).to_bool, no: sanitized_params.dig(:st_customer, :no).to_bool },
            stage_id:                          sanitized_params.dig(:stage_id).to_i,
            start_date_changes_only:           sanitized_params.dig(:start_date_changes_only).to_bool,
            status:                            sanitized_params.dig(:status).to_s,
            stop_campaign_ids:                 sanitized_params.dig(:stop_campaign_ids)&.compact_blank,
            tag_id:                            sanitized_params.dig(:tag_id).to_i,
            tag_ids_exclude:                   sanitized_params.dig(:tag_ids_exclude).compact_blank.map(&:to_i),
            tag_ids_include:                   sanitized_params.dig(:tag_ids_include).compact_blank.map(&:to_i),
            total_max:                         sanitized_params.dig(:total).to_s.split(';')[1].to_i,
            total_min:                         sanitized_params.dig(:total).to_s.split(';')[0].to_i
          }

          response
        end
        # example data received from form:
        # {
        #   'authenticity_token' => '[FILTERED]',
        #   'events'             => {
        #     'id'                                => '265',
        #     'action_type'                       => 'call_completed',
        #     'orphaned_estimates'                => 'false',
        #     'new_status'                        => [''],
        #     'job_cancel_reason_ids'             => [''],
        #     'customer_type'                     => [''],
        #     'status'                            => 'open',
        #     'job_types'                         => [''],
        #     'call_types'                        => [''],
        #     'call_reason_ids'                   => [''],
        #     'call_duration'                     => '60;180',
        #     'business_unit_ids'                 => [''],
        #     'membership_types'                  => [''],
        #     'membership_types_stop'             => [''],
        #     'membership'                        => [''],
        #     'ext_tech_ids'                      => [''],
        #     'tag_ids_include'                   => [''],
        #     'tag_ids_exclude'                   => [''],
        #     'start_date_changes_only'           => 'false',
        #     'range_max'                         => '1000',
        #     'total'                             => '0;0',
        #     'membership_days_prior'             => '90',
        #     'membership_campaign_stop_statuses' => [''],
        #     'assign_contact_to_user'            => 'false',
        #     'campaign_id'                       => '',
        #     'group_id'                          => '',
        #     'tag_id'                            => '',
        #     'stage_id'                          => '',
        #     'stop_campaign_ids'                 => ['']
        #   },
        #   'group'              => { 'events[group_id'=>{ '][name]'=>'' } },
        #   'tag'                => { 'events[tag_id'=>{ '][name]'=>'' } },
        #   'commit'             => 'Save Actions'
        # }

        def update_event_cookie(event_id)
          if RedisCloud.redis.get("user:#{current_user.id}:edit_servicetitan_event_shown").nil?
            initialize_event_cookie
          else
            cookie_hash = JSON.parse(RedisCloud.redis.get("user:#{current_user.id}:edit_servicetitan_event_shown"))
            cookie_hash[event_id] = (!cookie_hash[event_id].to_bool).to_s

            (@client_api_integration.events.keys - [event_id]).each do |e|
              cookie_hash[e] = 'false'
            end

            cookie_hash['0'] = 'false' unless event_id == '0'

            RedisCloud.redis.setex("user:#{current_user.id}:edit_servicetitan_event_shown", 1800, cookie_hash.to_json)
          end
        end
      end
    end
  end
end
