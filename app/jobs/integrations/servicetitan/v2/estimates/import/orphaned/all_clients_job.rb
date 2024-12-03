# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/import/orphaned/all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        module Import
          module Orphaned
            class AllClientsJob < ApplicationJob
              # Integrations::Servicetitan::V2::Estimates::Import::Orphaned::AllClientsJob.set(wait_until: 1.day.from_now).perform_later()
              # Integrations::Servicetitan::V2::Estimates::Import::Orphaned::AllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

              def initialize(**args)
                super

                @process          = (args.dig(:process).presence || 'servicetitan_import_orphaned_estimates_all_clients').to_s
                @reschedule_secs  = 0
              end

              # import orphaned estimates from ServiceTitan
              def perform(**args)
                super

                run_at = Time.current

                Client.active.with_integration_allowed('servicetitan').includes(:client_api_integrations).find_each do |client|
                  next unless (client_api_integration = client.client_api_integrations.find_by(target: 'servicetitan', name: ''))
                  next if client_api_integration.events.select { |_id, event| event.dig('orphaned_estimates').to_bool }.blank?

                  created_at_min = (client_api_integration.imported_orphaned_estimates_at.presence || 15.days.ago).to_time
                  created_at_max = Time.current

                  next if created_at_min >= created_at_max

                  client_api_integration.update(imported_orphaned_estimates_at: created_at_max.iso8601)

                  Integrations::Servicetitan::V2::Estimates::Import::Orphaned::ByClientJob.set(wait_until: run_at).perform_later(
                    client_id:      client.id,
                    created_at_max:,
                    created_at_min:
                  )

                  run_at += 10.seconds
                end
              end
            end
          end
        end
      end
    end
  end
end
