# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/jobs/balance/all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Jobs
        module Balance
          class AllClientsJob < ApplicationJob
            # step # 1 (all Clients)
            # update account balance for all ServiceTitan jobs within ClientApiIntegration.update_invoice_window_days range
            # Integrations::Servicetitan::V2::Jobs::Balance::AllClientsJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Jobs::Balance::AllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_job_balance_all_clients').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            def perform(**args)
              super

              run_at = Time.current

              Client.active.with_integration_allowed('servicetitan').select(:id).find_each do |client|
                Integrations::Servicetitan::V2::Jobs::Balance::ByClientJob.set(wait_until: run_at).perform_later(
                  client_id: client.id
                )

                run_at += 1.second
              end
            end
          end
        end
      end
    end
  end
end
