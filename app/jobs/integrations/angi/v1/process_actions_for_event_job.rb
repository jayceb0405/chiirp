# frozen_string_literal: true

# app/jobs/integrations/angi/v1/process_actions_for_event_job.rb
module Integrations
  module Angi
    module V1
      class ProcessActionsForEventJob < ApplicationJob
        # description of this job
        # Integrations::Angi::V1::ProcessActionsForEventJob.perform_now()
        # Integrations::Angi::V1::ProcessActionsForEventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Angi::V1::ProcessActionsForEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'angi_process_actions_for_event').to_s
        end

        # perform the ActiveJob
        #   (req) client_api_integration_id: (Integer)
        #   (req) contact_id:                (Integer)
        #   (req) client_id:                 (Integer)
        #   (req) event_id:                  (String)
        #   (opt) process_events:            (Boolean / default: false)
        #   (req) raw_params:                (Hash)
        def perform(**args)
          super

          return nil unless Integer(args.dig(:client_api_integration_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? &&
                            Integer(args.dig(:client_id), exception: false).present? && args.dig(:event_id).to_s.present? && args.dig(:raw_params).is_a?(Hash) &&
                            (contact = Contact.find_by(client_id: args[:client_id].to_i, id: args[:contact_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'angi', name: '')) &&
                            (event = client_api_integration.client.client_api_integrations.find_by(target: 'angi', name: 'events')&.events&.dig(args[:event_id])&.deep_symbolize_keys) &&
                            (ag_model = "Integration::Angi::V#{client_api_integration.data.dig('credentials', 'version').presence || Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new(client_api_integration)) && ag_model.valid_credentials?

          event.deep_symbolize_keys!

          response = []
          # response << ['FAIL event_new_criteria_pass?', args[:event_id].to_s, event, args.dig(:event_new).to_bool] unless event_new_criteria_pass?(event, args.dig(:event_new).to_bool)

          return response if response.present?

          response << ['PASS', args[:event_id].to_s, event, args]

          return response unless args.dig(:process_events).to_bool

          # contact.assign_user(client_api_integration.employees.dig(contact_job&.ext_tech_id)) if event.dig(:criteria, :assign_contact_to_user).to_bool && contact_job&.ext_tech_id.present? && client_api_integration.employees.dig(contact_job&.ext_tech_id).present?
          contact.process_actions(
            campaign_id:       event.dig(:actions, :campaign_id).to_i,
            group_id:          event.dig(:actions, :group_id).to_i,
            stage_id:          event.dig(:actions, :stage_id).to_i,
            tag_id:            event.dig(:actions, :tag_id).to_i,
            stop_campaign_ids: event.dig(:actions, :stop_campaign_ids)
          )

          response
        end

        # def event_new_criteria_pass?(event, event_new)
        #   %w[appointment_status_change subscription_status].exclude?(event.dig(:criteria, :event_type)) || !event.dig(:criteria, :event_new).to_bool || event_new
        # end
      end
    end
  end
end
