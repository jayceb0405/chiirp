# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/open/existing_all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        module Open
          class ExistingAllClientsJob < ApplicationJob
            # update existing open estimates from ServiceTitan for all Clients
            # Integrations::Servicetitan::V2::Estimates::Open::ExistingAllClientsJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Estimates::Open::ExistingAllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_existing_open_estimates_all_clients').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            def perform(**args)
              super

              run_at = Time.current

              Client.active.with_integration_allowed('servicetitan').find_each do |client|
                # only process at 6am & 9pm local time
                next unless [6, 21].include?(Time.current.in_time_zone(client.time_zone).hour)

                Integrations::Servicetitan::V2::Estimates::Open::ExistingByClientWithJobJob.set(wait_until: run_at).perform_later(
                  client_id: client.id
                )
                Integrations::Servicetitan::V2::Estimates::Open::ExistingByClientWithoutJobJob.set(wait_until: run_at).perform_later(
                  client_id: client.id,
                  with_job:  false
                )

                run_at += 5.seconds
              end
            end
          end
        end
      end
    end
  end
end
