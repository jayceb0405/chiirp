# frozen_string_literal: true

# app/controllers/integrations/angi/v1/events_controller.rb
module Integrations
  module Angi
    module V1
      class EventsController < Angi::V1::IntegrationsController
        # (DELETE) delete a Angi event
        # /integrations/angi/v1/events/:id
        # integrations_angi_v1_event_path(:id)
        # integrations_angi_v1_event_url(:id)
        def destroy
          @client_api_integration_events.events.delete(params[:id].to_s)
          @client_api_integration_events.save
        end

        # (GET) edit a Angi event
        # /integrations/angi/v1/events/:id/edit
        # edit_integrations_angi_v1_event_path(:id)
        # edit_integrations_angi_v1_event_url(:id)
        def edit
          @event_id = params.dig(:id)
        end

        # (GET) list Angi events
        # /integrations/angi/v1/events
        # integrations_angi_v1_events_path
        # integrations_angi_v1_events_url
        def index; end

        # (GET) initialize a new Angi event
        # /integrations/angi/v1/events/new
        # new_integrations_angi_v1_event_path
        # new_integrations_angi_v1_event_url
        def new
          @event_id = SecureRandom.uuid
          @client_api_integration_events.update(events: @client_api_integration_events.events.merge({ @event_id => default_event }))
        end

        # (PUT/PATCH) update a Angi event
        # /integrations/angi/v1/events/:id
        # integrations_angi_v1_event_path(:id)
        # integrations_angi_v1_event_url(:id)
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
              event_type: '',
              name:       'New Event'
            }
          }
        end

        def params_update_events
          response = @client_api_integration_events.events
          sanitized_params = params.require(:event).permit(:event_type, :campaign_id, :group_id, :id, :name, :stage_id, :tag_id, stop_campaign_ids: [])

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
              event_type: sanitized_params.dig(:event_type).to_s,
              name:       sanitized_params.dig(:name).to_s
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
