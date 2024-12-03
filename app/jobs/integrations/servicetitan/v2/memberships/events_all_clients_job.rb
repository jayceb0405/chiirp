# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/memberships/events_all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Memberships
        class EventsAllClientsJob < ApplicationJob
          # trigger events for membership expirations for each Client
          # Integrations::Servicetitan::V2::Memberships::EventsAllClientsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Memberships::EventsAllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_membership_events_all_clients').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          def perform(**args)
            super

            Client.active.with_integration_allowed('servicetitan').includes(:client_api_integrations).find_each do |client|
              next unless client.client_api_integrations.find_by(target: 'servicetitan', name: '')

              Integrations::Servicetitan::V2::Memberships::EventsByClientJob.perform_later(client_id: client.id, block_count: 5000)
            end
          end
        end
      end
    end
  end
end
