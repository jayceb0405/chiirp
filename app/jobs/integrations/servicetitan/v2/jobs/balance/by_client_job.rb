# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/jobs/balance/by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Jobs
        module Balance
          class ByClientJob < ApplicationJob
            # step # 2 (a Client)
            # update account balance for all ServiceTitan jobs within ClientApiIntegration update_invoice_window_days range
            # Integrations::Servicetitan::V2::Jobs::Balance::ByClientJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Jobs::Balance::ByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_job_balance_by_client').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id: (Integer)
            def perform(**args)
              super

              return unless args.dig(:client_id).to_i.positive? &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            client_api_integration.update_balance_actions.dig('update_invoice_window_days').to_i.positive? &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              run_at = Time.current

              Contacts::Job.select(:id, :contact_id, :ext_id).joins(:contact).where(contact: { client_id: args[:client_id].to_i }, invoice_date: [client_api_integration.update_balance_actions['update_invoice_window_days'].to_i.days.ago..Time.current]).where.not(outstanding_balance: 0).in_groups_of(50, false) do |contact_jobs|
                st_job_models      = st_client.jobs(st_job_ids: contact_jobs.map(&:ext_id).uniq)
                st_customer_models = st_client.customers(st_customer_ids: st_job_models.map { |jm| jm.dig(:customerId) }.uniq)
                run_at             = [run_at + 1.second, Time.current].max

                contact_jobs.each do |contact_job|
                  st_job_model = st_job_models.find { |jm| jm[:id] == contact_job.ext_id.to_i }

                  Integrations::Servicetitan::V2::Jobs::Balance::ByJobJob.set(wait_until: run_at).perform_later(
                    client_id:         args[:client_id].to_i,
                    contact_id:        contact_job.contact_id,
                    contact_job_id:    contact_job.id,
                    st_customer_model: st_customer_models.find { |cm| cm[:id] == st_job_model&.dig(:customerId) },
                    st_job_model:
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
