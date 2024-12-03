# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/jobs/open/existing_all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Jobs
        module Open
          class ExistingAllClientsJob < ApplicationJob
            # trigger events for membership expirations for each Client
            # Integrations::Servicetitan::V2::Jobs::Open::ExistingAllClientsJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Jobs::Open::ExistingAllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_existing_open_jobs_all_clients').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            def perform(**args)
              super

              run_at = Time.current

              Client.active.with_integration_allowed('servicetitan').select(:id, :time_zone).find_each do |client|
                # do not process between the hours of 10pm & 6am local time
                next if Time.current.in_time_zone(client.time_zone).hour < 6 || Time.current.in_time_zone(client.time_zone).hour > 21
                # only process every 3 hours local time
                next if Time.current.in_time_zone(client.time_zone).hour % 3 != 0

                Integrations::Servicetitan::V2::Jobs::Open::ExistingByClientJob.set(wait_until: run_at).perform_later(
                  client_id: client.id,
                  hour:      Time.current.in_time_zone(client.time_zone).hour
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
