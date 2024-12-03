# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/open/existing_by_client_with_job_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        module Open
          class ExistingByClientWithJobJob < ApplicationJob
            # update existing open estimates attached to a job from ServiceTitan for a Client
            # Integrations::Servicetitan::V2::Estimates::Open::ExistingByClientWithJobJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Estimates::Open::ExistingByClientWithJobJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_existing_open_estimates_by_client').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id: (Integer)
            def perform(**args)
              super

              return unless args.dig(:client_id).to_i.positive? &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              st_estimate_models = []

              Contacts::Estimate.select(contact_estimates: { id: :id, ext_id: :ext_id }, contact_jobs: { ext_id: :job_ext_id }).joins(:contact, :job).where(contact: { client_id: args[:client_id].to_i }, ext_source: 'servicetitan', status: 'open', updated_at: [client_api_integration.update_balance_actions.dig('update_open_estimate_window_days').to_i.days.ago..Time.current]).in_groups_of(50, false) do |contact_estimates|
                st_estimate_models += st_client.estimates(st_estimate_ids: contact_estimates.map(&:ext_id))
              end

              st_job_models = []

              st_estimate_models.pluck(:jobId).in_groups_of(50, false) do |st_job_model_ids|
                st_job_models += st_client.jobs(st_job_ids: st_job_model_ids.uniq)
              end

              st_customer_models = []

              st_job_models.pluck(:customerId).uniq.in_groups_of(50, false) do |st_customer_model_ids|
                st_customer_models += st_client.customers(st_customer_ids: st_customer_model_ids)
              end

              st_location_models = []

              st_job_models.pluck(:locationId).uniq.in_groups_of(50, false) do |st_location_model_ids|
                st_location_models += st_client.locations(st_location_ids: st_location_model_ids)
              end

              contact_ids = Contact.select(contacts: { id: :id }, contact_ext_references: { ext_id: :ext_id }).joins(:ext_references).where(client_id: args[:client_id].to_i, contact_ext_references: { ext_id: st_job_models.pluck(:customerId) })
              run_at      = Time.current

              st_job_models.uniq.each do |st_job_model|
                Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: run_at).perform_later(
                  contact_id:                     contact_ids.find { |ci| ci.ext_id.to_i == st_job_model[:customerId] }&.id,
                  ok_to_process_estimate_actions: true,
                  st_customer_model:              st_customer_models.find { |cm| cm[:id] == st_job_model[:customerId] },
                  st_estimate_models:             st_estimate_models.select { |em| em[:jobId] == st_job_model[:id] },
                  st_location_model:              st_location_models.find { |lm| lm[:id] == st_job_model[:locationId] },
                  st_job_model:
                )

                run_at += 1.second
              end
            end

            def max_run_time
              600 # seconds
            end
          end
        end
      end
    end
  end
end
