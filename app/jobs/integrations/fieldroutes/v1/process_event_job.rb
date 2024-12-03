# frozen_string_literal: true

# app/jobs/integrations/fieldroutes/v1/process_event_job.rb
module Integrations
  module Fieldroutes
    module V1
      class ProcessEventJob < ApplicationJob
        # description of this job
        # Integrations::Fieldroutes::V1::ProcessEventJob.perform_now()
        # Integrations::Fieldroutes::V1::ProcessEventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Fieldroutes::V1::ProcessEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'fieldroutes_process_event').to_s
        end

        # perform the ActiveJob
        #   (req) client_api_integration_id: (Integer)
        #   (req) client_id:                 (Integer)
        #   (req) event_id:                  (String)
        #   (opt) process_events:            (Boolean / default: false)
        #   (req) raw_params:                (Hash)
        def perform(**args)
          super

          return unless Integer(args.dig(:client_api_integration_id), exception: false).present? && Integer(args.dig(:client_id), exception: false).present? &&
                        args.dig(:event_id).to_s.present? && args.dig(:raw_params).present? &&
                        (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'fieldroutes', name: '')) &&
                        (fr_model = "Integration::Fieldroutes::V#{client_api_integration.data.dig('credentials', 'version')}::Base".constantize.new(client_api_integration)) && fr_model.valid_credentials? &&
                        (contact = fr_model.contact(**args.dig(:raw_params)))

          case args.dig(:raw_params, :event)
          when 'appointment_status_change'
            event_new = contact.raw_posts.where(ext_id: args.dig(:raw_params, :event)).where('data @> ?', { appointmentID: args.dig(:raw_params, :appointmentID) }.to_json).order(created_at: :desc).none?
          when 'subscription_status'
            event_new = contact.raw_posts.where(ext_id: args.dig(:raw_params, :event)).where('data @> ?', { subscriptionID: args.dig(:raw_params, :subscriptionID) }.to_json).order(created_at: :desc).none?
          end

          # save params to Contact::RawPosts
          contact.raw_posts.create(ext_source: 'fieldroutes', ext_id: args.dig(:raw_params, :event), data: args.dig(:raw_params))

          case args.dig(:raw_params, :event)
          when 'appointment_status_change'
            contact_job          = fr_model.job(contact, **args.dig(:raw_params))
            contact_subscription = nil
          when 'subscription_status'
            contact_job          = nil
            contact_subscription = fr_model.subscription(contact, **args.dig(:raw_params))
          else
            return
          end

          start_date_updated   = contact_job.blank? || fr_model.scheduled_start_at_from_webhook(contact, **args.dig(:raw_params)) != contact_job.scheduled_start_at
          tech_updated         = contact_job.blank? || args.dig(:raw_params, :servicedBy).to_s != contact_job.ext_tech_id
          total                = contact_job&.total_amount || contact_subscription&.total
          total_due            = contact_subscription&.total_due

          Integrations::Fieldroutes::V1::ProcessActionsForEventJob.perform_later(
            client_api_integration_id: client_api_integration.id,
            client_id:                 args[:client_id],
            contact_id:                contact.id,
            contact_job_id:            contact_job&.id,
            event_id:                  args[:event_id],
            event_new:,
            ext_tech_id:               contact_job&.ext_tech_id,
            process_events:            true,
            raw_params:                args[:raw_params],
            start_date_updated:,
            tech_updated:,
            total:,
            total_due:
          )
        end
      end
    end
  end
end
