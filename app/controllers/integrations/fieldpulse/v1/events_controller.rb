# frozen_string_literal: true

# app/controllers/integrations/fieldpulse/v1/events_controller.rb
module Integrations
  module Fieldpulse
    module V1
      class EventsController < Fieldpulse::V1::IntegrationsController
        # (DELETE) delete a FieldPulse event
        # /integrations/fieldpulse/v1/events/:id
        # integrations_fieldpulse_v1_event_path(:id)
        # integrations_fieldpulse_v1_event_url(:id)
        def destroy
          @client_api_integration_events.events.delete(params[:id].to_s)
          @client_api_integration_events.save
        end

        # (GET) edit a FieldPulse event
        # /integrations/fieldpulse/v1/events/:id/edit
        # edit_integrations_fieldpulse_v1_event_path(:id)
        # edit_integrations_fieldpulse_v1_event_url(:id)
        def edit
          @event_id = params.dig(:id)
        end

        # (GET) list FieldPulse events
        # /integrations/fieldpulse/v1/events
        # integrations_fieldpulse_v1_events_path
        # integrations_fieldpulse_v1_events_url
        def index; end

        # (GET) initialize a new FieldPulse event
        # /integrations/fieldpulse/v1/events/new
        # new_integrations_fieldpulse_v1_event_path
        # new_integrations_fieldpulse_v1_event_url
        def new
          @event_id = SecureRandom.uuid
          @client_api_integration_events.update(events: @client_api_integration_events.events.merge({ @event_id => default_event }))
        end

        # (GET) refresh FieldPulse workflows
        # /integrations/fieldpulse/v1/events/refresh_workflows/:id
        # integrations_fieldpulse_v1_event_refresh_workflows_path(:id)
        # integrations_fieldpulse_v1_event_refresh_workflows_url(:id)
        def refresh_workflows
          @event_id = params.dig(:id)
          Integration::Fieldpulse::V1::Base.new(@client_api_integration).refresh_job_status_workflows
        end

        # (PUT/PATCH) update a FieldPulse event
        # /integrations/fieldpulse/v1/events/:id
        # integrations_fieldpulse_v1_event_path(:id)
        # integrations_fieldpulse_v1_event_url(:id)
        def update
          @client_api_integration_events.update(events: params_update_events)
        end

        private

        def default_event
          {
            actions:  {
              campaign_id:       0,
              group_id:          0,
              stage_id:          0,
              stop_campaign_ids: [],
              tag_id:            0
            },
            criteria: {
              event_type:                'job',
              event_workflow_id:         0,
              event_workflow_status_ids: [],
              event_new:                 true,
              event_updated:             true,
              ext_tech_ids:              [],
              range_max:                 1_000,
              start_date_updated:        false,
              tech_updated:              false,
              total_max:                 1_000,
              total_min:                 0
            }
          }
        end

        def params_update_events
          response = @client_api_integration_events.events
          sanitized_params = params.require(:event).permit(:event_type, :assign_contact_to_user, :campaign_id, :event_new, :event_updated, :event_workflow_id, :group_id, :id, :range_max, :stage_id, :start_date_updated, :tag_id, :tech_updated, :total, :total_due, event_workflow_status_ids: [], ext_tech_ids: [], stop_campaign_ids: [])

          sanitized_params[:stop_campaign_ids] = [0] if sanitized_params[:stop_campaign_ids]&.include?('0') # no need to keep other ids

          response[sanitized_params.dig(:id)] = {
            actions:  {
              campaign_id:       sanitized_params.dig(:campaign_id).to_i,
              group_id:          sanitized_params.dig(:group_id).to_i,
              stage_id:          sanitized_params.dig(:stage_id).to_i,
              stop_campaign_ids: sanitized_params.dig(:stop_campaign_ids)&.compact_blank,
              tag_id:            sanitized_params.dig(:tag_id).to_i
            },
            criteria: {
              event_type:                sanitized_params.dig(:event_type).to_s,
              assign_contact_to_user:    sanitized_params.dig(:assign_contact_to_user).to_bool,
              event_new:                 sanitized_params.dig(:event_new).to_bool,
              event_updated:             sanitized_params.dig(:event_updated).to_bool,
              event_workflow_id:         sanitized_params.dig(:event_workflow_id).to_i,
              event_workflow_status_ids: sanitized_params.dig(:event_workflow_status_ids).compact_blank.map(&:to_i),
              ext_tech_ids:              sanitized_params.dig(:ext_tech_ids)&.compact_blank&.map(&:to_i),
              range_max:                 sanitized_params.dig(:range_max).to_i,
              start_date_updated:        sanitized_params.dig(:start_date_updated).to_bool,
              tech_updated:              sanitized_params.dig(:tech_updated).to_bool,
              total_max:                 sanitized_params.dig(:total).to_s.split(';')[1].to_i,
              total_min:                 sanitized_params.dig(:total).to_s.split(';')[0].to_i,
              total_due_max:             sanitized_params.dig(:total_due).to_s.split(';')[1].to_i,
              total_due_min:             sanitized_params.dig(:total_due).to_s.split(';')[0].to_i
            }
          }

          response
        end
        # example data received from form:
        # {
        #   authenticity_token: '[FILTERED]',
        #   event:              {
        #     id:                     'c9748edb-670c-4537-ac2f-5f92449211d5',
        #     event_type:             'appointment_status_change',
        #     ext_tech_ids:           ['', '1403', '679', '1013'],
        #     range_max:              '1000',
        #     total:                  '0;1000',
        #     assign_contact_to_user: 'false',
        #     campaign_id:            '',
        #     group_id:               '',
        #     tag_id:                 '179',
        #     stage_id:               '',
        #     stop_campaign_ids:      ['']
        #   },
        #   group:              { name: '' },
        #   tag:                {"event[tag_id"=>{"][name]"=>""} },
        #   commit:             'Save Actions',
        #   id:                 'c9748edb-670c-4537-ac2f-5f92449211d5'
        # }
      end
    end
  end
end
