# frozen_string_literal: true

# app/jobs/integrations/fieldpulse/v1/process_actions_for_event_job.rb
module Integrations
  module Fieldpulse
    module V1
      class ProcessActionsForEventJob < ApplicationJob
        # description of this job
        # Integrations::Fieldpulse::V1::ProcessActionsForEventJob.perform_now()
        # Integrations::Fieldpulse::V1::ProcessActionsForEventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Fieldpulse::V1::ProcessActionsForEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'fieldpulse_process_actions_for_event').to_s
        end

        # perform the ActiveJob
        #   (req) client_api_integration_id: (Integer)
        #   (req) contact_id:                (Integer)
        #   (opt) contact_job_id:            (Integer / default: 0)
        #   (req) client_id:                 (Integer)
        #   (opt) event_new:                 (Boolean / default: false)
        #   (opt) ext_tech_id:               (String / default: '')
        #   (opt) process_events:            (Boolean / default: false)
        #   (req) raw_params:                (Hash)
        #   (opt) start_date_updated:        (Boolean / default: false)
        #   (opt) status_id:                 (Integer / default: 0)
        #   (opt) status_workflow_id:        (Integer / default: 0)
        #   (opt) tech_updated:              (Boolean / default: false)
        #   (opt) total:                     (BigDecimal / default: 0.0)
        def perform(**args)
          super

          return nil unless Integer(args.dig(:client_api_integration_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? &&
                            Integer(args.dig(:client_id), exception: false).present? && args.dig(:raw_params).is_a?(Hash) &&
                            (contact = Contact.find_by(client_id: args[:client_id].to_i, id: args[:contact_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'fieldpulse', name: '')) &&
                            (client_api_integration_events = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'fieldpulse', name: 'events')) &&
                            (fp_model = Integration::Fieldpulse::V1::Base.new(client_api_integration)) && fp_model.valid_credentials?

          client_api_integration_events.events.each do |event_id, event|
            event.deep_symbolize_keys!

            response  = []
            response << ['FAIL event_new_or_updated_criteria_pass?', "Event id: #{event_id}", "Event New: #{args.dig(:event_new).to_bool}", "Criteria Event New: #{event.dig(:criteria, :event_new).to_bool}", "Criteria Event Updated: #{event.dig(:criteria, :event_updated).to_bool}"] unless event_new_or_updated_criteria_pass?(event, args.dig(:event_new).to_bool)
            response << ['FAIL event_start_date_updated_criteria_pass?', "Event id: #{event_id}", "Event New: #{args.dig(:event_new).to_bool}", "Event Start Date Updated: #{args.dig(:start_date_updated).to_bool}", "Criteria Start Date Updated: #{event.dig(:criteria, :start_date_updated).to_bool}"] unless event_start_date_updated_criteria_pass?(event, args.dig(:event_new).to_bool, args.dig(:start_date_updated).to_bool)
            response << ['FAIL event_tech_updated_criteria_pass?', "Event id: #{event_id}", "Event New: #{args.dig(:event_new).to_bool}", "Event Tech Updated: #{args.dig(:tech_updated).to_bool}", "Criteria Tech Updated: #{event.dig(:criteria, :tech_updated).to_bool}"] unless event_tech_updated_criteria_pass?(event, args.dig(:event_new).to_bool, args.dig(:tech_updated).to_bool)
            response << ['FAIL event_ext_tech_id_match_criteria_pass?', "Event id: #{event_id}", "Event Tech ID: #{args.dig(:ext_tech_id)}", "Criteria Tech IDs: #{event.dig(:criteria, :ext_tech_ids)}"] unless event_ext_tech_id_match_criteria_pass?(event, args.dig(:ext_tech_id))
            response << ['FAIL event_total_criteria_pass?', "Event id: #{event_id}", "Event Total: #{args.dig(:total)}", "Criteria Total: #{event.dig(:criteria, :total_min).to_i} - #{event.dig(:criteria, :total_max).to_i}"] unless event_total_criteria_pass?(event, args.dig(:total))
            response << ['FAIL event_status_criteria_pass?', "Event id: #{event_id}", "Event Workflow Status: #{args.dig(:status_id)}", "Criteria Workflow Statuses: #{event.dig(:criteria, :event_workflow_status_ids)}"] unless event_status_criteria_pass?(event, args.dig(:status_id))
            response << ['FAIL event_workflow_criteria_pass?', "Event id: #{event_id}", "Event Workflow: #{args.dig(:status_workflow_id)}", "Criteria Workflow: #{event.dig(:criteria, :event_workflow_id)}"] unless event_workflow_criteria_pass?(event, args.dig(:status_workflow_id))

            Rails.logger.info "response: #{response.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }" if response.present?
            return response if response.present?

            response << ['PASS', event_id, event, args]

            return response unless args.dig(:process_events).to_bool

            # contact.assign_user(client_api_integration.employees.dig(contact_job&.ext_tech_id)) if event.dig(:criteria, :assign_contact_to_user).to_bool && contact_job&.ext_tech_id.present? && client_api_integration.employees.dig(contact_job&.ext_tech_id).present?
            contact.process_actions(
              campaign_id:       event.dig(:actions, :campaign_id).to_i,
              group_id:          event.dig(:actions, :group_id).to_i,
              stage_id:          event.dig(:actions, :stage_id).to_i,
              tag_id:            event.dig(:actions, :tag_id).to_i,
              stop_campaign_ids: event.dig(:actions, :stop_campaign_ids),
              contact_job_id:    args.dig(:contact_job_id)
            )
          end

          response
        end

        def event_ext_tech_id_match_criteria_pass?(event, ext_tech_id)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || event.dig(:criteria, :ext_tech_ids).blank? || event.dig(:criteria, :ext_tech_ids).include?(ext_tech_id.to_i)
        end

        def event_new_or_updated_criteria_pass?(event, event_new)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || event.dig(:criteria, :event_new).to_bool == event_new || event.dig(:criteria, :event_updated).to_bool == !event_new
        end

        def event_start_date_updated_criteria_pass?(event, event_new, start_date_updated)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || event_new || event.dig(:criteria, :start_date_updated).to_bool == start_date_updated
        end

        def event_status_criteria_pass?(event, status_id)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || event.dig(:criteria, :event_workflow_status_ids).blank? || event.dig(:criteria, :event_workflow_status_ids).include?(status_id)
        end

        def event_tech_updated_criteria_pass?(event, event_new, tech_updated)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || event_new || event.dig(:criteria, :tech_updated).to_bool == tech_updated
        end

        def event_total_criteria_pass?(event, total)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || (event.dig(:criteria, :total_min).to_i + event.dig(:criteria, :total_max).to_i).zero? || (event.dig(:criteria, :total_min).to_i..event.dig(:criteria, :total_max).to_i).include?(total)
        end

        def event_workflow_criteria_pass?(event, status_workflow_id)
          %w[job].exclude?(event.dig(:criteria, :event_type)) || event.dig(:criteria, :event_workflow_id).to_i.zero? || event.dig(:criteria, :event_workflow_id).to_i == status_workflow_id.to_i
        end
      end
    end
  end
end
