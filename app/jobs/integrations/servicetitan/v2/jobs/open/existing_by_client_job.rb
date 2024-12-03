# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/jobs/open/existing_by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Jobs
        module Open
          class ExistingByClientJob < ApplicationJob
            # trigger events for membership expirations for each Client
            # Integrations::Servicetitan::V2::Jobs::Open::ExistingByClientJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Jobs::Open::ExistingByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_existing_open_jobs_by_client').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id: (Integer)
            #   (req) hour:      (Integer)
            def perform(**args)
              super

              return unless args.dig(:client_id).to_i.positive? && args.dig(:hour).to_i.positive? &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              run_at = Time.current

              Contacts::Job.select(:id, :contact_id, :ext_id).joins(:contact)
                           .where(contact: { client_id: args[:client_id].to_i }, updated_at: [updated_at_from(client_api_integration, args[:hour])..Time.current])
                           .where.not(status: %w[Canceled Completed])
                           .in_groups_of(50, false) do |contact_jobs|
                st_job_models        = st_client.jobs(st_job_ids: contact_jobs.map(&:ext_id).uniq)
                st_customer_models   = st_client.customers(st_customer_ids: st_job_models.map { |jm| jm.dig(:customerId) }.uniq)
                st_membership_models = st_client.customer_memberships(
                  active_only:     true,
                  status:          'Active',
                  st_customer_ids: st_customer_models.pluck(:id)
                )
                st_job_cancel_reasons = st_client.job_cancel_reasons(st_job_models.map { |jm| jm.dig(:id) }.uniq)

                contact_jobs.each do |contact_job|
                  st_job_model      = st_job_models.find { |jm| jm[:id] == contact_job.ext_id.to_i }
                  st_customer_model = st_customer_models.find { |cm| cm[:id] = st_job_model&.dig(:customerId) }

                  Integrations::Servicetitan::V2::Jobs::Open::ExistingByJobJob.set(wait_until: run_at).perform_later(
                    contact_id:            contact_job.contact_id,
                    client_id:             args[:client_id].to_i,
                    contact_job_id:        contact_job.id,
                    st_customer_model:,
                    st_job_model:,
                    st_job_cancel_reasons: st_job_cancel_reasons.select { |jcr| jcr[:jobId] == st_job_model&.dig(:id) } || [],
                    st_membership_models:  st_membership_models.select { |mm| mm[:customerId] == st_customer_model&.dig(:id) } || []
                  )
                  run_at += 1.second
                end
              end
            end

            def max_run_time
              3600 # seconds (60 minutes)
            end

            private

            def updated_at_from(client_api_integration, hour)
              if hour == 6
                [365, client_api_integration.update_balance_actions.dig('update_open_job_window_days').to_i].min.days.ago
              elsif hour == 21
                [180, client_api_integration.update_balance_actions.dig('update_open_job_window_days').to_i].min.days.ago
              elsif (hour % 6).zero?
                [90, client_api_integration.update_balance_actions.dig('update_open_job_window_days').to_i].min.days.ago
              else
                [30, client_api_integration.update_balance_actions.dig('update_open_job_window_days').to_i].min.days.ago
              end
            end
          end
        end
      end
    end
  end
end
