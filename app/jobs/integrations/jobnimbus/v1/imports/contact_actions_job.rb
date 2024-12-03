# frozen_string_literal: true

# app/jobs/integrations/jobnimbus/v1/imports/contact_actions_job.rb
module Integrations
  module Jobnimbus
    module V1
      module Imports
        class ContactActionsJob < ApplicationJob
          # description of this job
          # Integrations::Jobnimbus::V1::Imports::ContactActionsJob.perform_now()
          # Integrations::Jobnimbus::V1::Imports::ContactActionsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobnimbus::V1::Imports::ContactActionsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'process_actions_for_webhook').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:  (Integer)
          #   (req) contact_id: (Integer)
          #   (req) criteria:   (Hash)
          #     (opt) contact_estimate_id: (Integer / default nil)
          #     (opt) contact_job_id:      (Integer / default nil)
          #     (opt) event_new:    (Boolean / default: false)
          #     (opt) event_status: (String / default: '')
          #     (opt) status:       (String / default: '')
          #     (opt) task_type:    (String / default: '')
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? && args.dig(:actions).is_a?(Hash) &&
                          (contact = Contact.find_by(client_id: args[:client_id].to_i, id: args[:contact_id].to_i))

            event_status = args.dig(:criteria, :event_status).to_s.split('_').first

            client_api_integration.webhooks.deep_symbolize_keys.dig(event_status.to_sym)&.each do |webhook_event|
              next unless (webhook_event.dig(:criteria, :event_new).to_bool && args.dig(:criteria, :event_new).to_bool) || (webhook_event.dig(:criteria, :event_updated).to_bool && !args.dig(:criteria, :event_new).to_bool)
              next unless webhook_event.dig(:criteria, :status).blank? || webhook_event.dig(:criteria, :status).to_s == args.dig(:criteria, :status)
              next unless event_status != 'task' || webhook_event.dig(:criteria, :task_types).blank? || webhook_event.dig(:criteria, :task_types).include?(args.dig(:criteria, :task_type))

              contact.process_actions(
                campaign_id:         webhook_event.dig(:actions, :campaign_id),
                group_id:            webhook_event.dig(:actions, :group_id),
                stage_id:            webhook_event.dig(:actions, :stage_id),
                tag_id:              webhook_event.dig(:actions, :tag_id),
                stop_campaign_ids:   webhook_event.dig(:actions, :stop_campaign_ids),
                contact_estimate_id: args.dig(:criteria, :contact_estimate_id),
                contact_job_id:      args.dig(:criteria, :contact_job_id)
              )
            end
          end
        end
      end
    end
  end
end
