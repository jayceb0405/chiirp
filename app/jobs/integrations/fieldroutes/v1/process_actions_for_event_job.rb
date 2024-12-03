# frozen_string_literal: true

# app/jobs/integrations/fieldroutes/v1/process_actions_for_event_job.rb
module Integrations
  module Fieldroutes
    module V1
      class ProcessActionsForEventJob < ApplicationJob
        # description of this job
        # Integrations::Fieldroutes::V1::ProcessActionsForEventJob.perform_now()
        # Integrations::Fieldroutes::V1::ProcessActionsForEventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Fieldroutes::V1::ProcessActionsForEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'fieldroutes_process_actions_for_event').to_s
        end

        # perform the ActiveJob
        #   (req) client_api_integration_id: (Integer)
        #   (req) contact_id:                (Integer)
        #   (opt) contact_job_id:            (Integer)
        #   (req) client_id:                 (Integer)
        #   (req) event_id:                  (String)
        #   (opt) event_new:                 (Boolean / default: false)
        #   (opt) ext_tech_id:               (String)
        #   (opt) process_events:            (Boolean / default: false)
        #   (req) raw_params:                (Hash)
        #   (opt) start_date_updated:        (Boolean / default: false)
        #   (opt) tech_updated:              (Boolean / default: false)
        #   (opt) total:                     (BigDecimal)
        #   (opt) total_due:                 (BigDecimal)
        def perform(**args)
          super

          return nil unless Integer(args.dig(:client_api_integration_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? &&
                            Integer(args.dig(:client_id), exception: false).present? && args.dig(:event_id).to_s.present? && args.dig(:raw_params).is_a?(Hash) &&
                            (contact = Contact.find_by(client_id: args[:client_id].to_i, id: args[:contact_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'fieldroutes', name: '')) &&
                            (client_api_integration_events = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'fieldroutes', name: 'events')) &&
                            (event = client_api_integration_events.events.dig(args[:event_id].to_s)).present? &&
                            (fr_model = "Integration::Fieldroutes::V#{client_api_integration.data.dig('credentials', 'version')}::Base".constantize.new(client_api_integration)) && fr_model.valid_credentials?

          event.deep_symbolize_keys!

          response  = []
          response << ['FAIL event_new_criteria_pass?', args[:event_id].to_s, event, args.dig(:event_new).to_bool] unless event_new_criteria_pass?(event, args.dig(:event_new).to_bool)
          response << ['FAIL event_updated_criteria_pass?', args[:event_id].to_s, event, args.dig(:event_new).to_bool] unless event_updated_criteria_pass?(event, args.dig(:event_new).to_bool)
          response << ['FAIL event_start_date_updated_criteria_pass?', args[:event_id].to_s, event, args.dig(:start_date_updated).to_bool] unless event_start_date_updated_criteria_pass?(event, args.dig(:start_date_updated).to_bool)
          response << ['FAIL event_tech_updated_criteria_pass?', args[:event_id].to_s, event, args.dig(:tech_updated).to_bool] unless event_tech_updated_criteria_pass?(event, args.dig(:tech_updated).to_bool)
          response << ['FAIL event_ext_tech_id_match_criteria_pass?', args[:event_id].to_s, event, args.dig(:ext_tech_id)] unless event_ext_tech_id_match_criteria_pass?(event, args.dig(:ext_tech_id))
          response << ['FAIL event_total_criteria_pass?', args[:event_id].to_s, event, args.dig(:total)] unless event_total_criteria_pass?(event, args.dig(:total))
          response << ['FAIL event_total_due_criteria_pass?', args[:event_id].to_s, event, args.dig(:total)] unless event_total_due_criteria_pass?(event, args.dig(:total_due))

          return response if response.present?

          response << ['PASS', args[:event_id].to_s, event, args]

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

          response
        end

        def event_ext_tech_id_match_criteria_pass?(event, ext_tech_id)
          %w[appointment_status_change].exclude?(event.dig(:criteria, :event_type)) || event.dig(:criteria, :ext_tech_ids).blank? || event.dig(:criteria, :ext_tech_ids).include?(ext_tech_id)
        end

        def event_new_criteria_pass?(event, event_new)
          %w[appointment_status_change subscription_status].exclude?(event.dig(:criteria, :event_type)) || !event.dig(:criteria, :event_new).to_bool || event_new
        end

        def event_start_date_updated_criteria_pass?(event, start_date_updated)
          %w[appointment_status_change].exclude?(event.dig(:criteria, :event_type)) || !event.dig(:criteria, :start_date_updated).to_bool || start_date_updated
        end

        def event_tech_updated_criteria_pass?(event, tech_updated)
          %w[appointment_status_change].exclude?(event.dig(:criteria, :event_type)) || !event.dig(:criteria, :tech_updated) || tech_updated
        end

        def event_total_criteria_pass?(event, total)
          %w[appointment_status_change subscription_status].exclude?(event.dig(:criteria, :event_type)) || (event.dig(:criteria, :total_min).to_i + event.dig(:criteria, :total_max).to_i).zero? || (event.dig(:criteria, :total_min).to_i..event.dig(:criteria, :total_max).to_i).include?(total)
        end

        def event_total_due_criteria_pass?(event, total_due)
          %w[subscription_status].exclude?(event.dig(:criteria, :event_type)) || (event.dig(:criteria, :total_due_min).to_i + event.dig(:criteria, :total_due_max).to_i).zero? || (event.dig(:criteria, :total_due_min).to_i..event.dig(:criteria, :total_due_max).to_i).include?(total_due)
        end

        def event_updated_criteria_pass?(event, event_new)
          %w[appointment_status_change subscription_status].exclude?(event.dig(:criteria, :event_type)) || !event.dig(:criteria, :event_updated).to_bool || !event_new
        end
      end
    end
  end
end
