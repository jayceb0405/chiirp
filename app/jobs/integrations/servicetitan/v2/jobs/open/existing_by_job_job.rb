# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/jobs/open/existing_by_job_job.rb
module Integrations
  module Servicetitan
    module V2
      module Jobs
        module Open
          class ExistingByJobJob < ApplicationJob
            # update existing open jobs from ServiceTitan for a Job
            # Integrations::Servicetitan::V2::Jobs::Open::ExistingByJobJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Jobs::Open::ExistingByJobJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_existing_open_jobs_by_job').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id:             (Integer)
            #   (req) contact_job_id:        (Integer)
            #   (req) st_customer_model:     (Hash)
            #   (req) st_job_model:          (Hash)
            #
            #   (opt) st_job_cancel_reasons: (Array)
            #   (opt) st_membership_models:  (Array)
            def perform(**args)
              super

              return unless args.dig(:client_id).to_i.positive? && args.dig(:contact_job_id).to_i.positive? &&
                            args.dig(:st_job_model).present? && args[:st_job_model].is_a?(Hash) &&
                            args.dig(:st_customer_model).present? && args[:st_customer_model].is_a?(Hash) &&
                            (contact_job = Contacts::Job.find_by(id: args[:contact_job_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials?

              previous_status = contact_job.status

              return unless (contact_job = st_model.update_contact_job_from_job_model(contact_job.contact, args[:st_job_model]))

              Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
                contact_id:            contact_job.contact_id,
                action_type:           'job_status_changed',
                business_unit_id:      args[:st_job_model].dig(:businessUnitId),
                contact_job_id:        contact_job.id,
                customer_type:         args[:st_customer_model].dig(:type),
                ext_tag_ids:           st_model.tag_names_to_ids(contact_job.contact.tags.pluck(:name)),
                ext_tech_id:           contact_job.ext_tech_id.to_i,
                job_cancel_reason_ids: contact_job.status.casecmp?('Canceled') ? args.dig(:st_job_cancel_reasons)&.pluck(:reasonId) || [] : [],
                job_status:            contact_job.status,
                job_status_changed:    contact_job.status != previous_status,
                job_type_id:           args[:st_job_model].dig(:jobTypeId),
                membership:            args.dig(:st_membership_models).present?,
                total_amount:          contact_job.total_amount
              )
            end
          end
        end
      end
    end
  end
end
