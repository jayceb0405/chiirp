# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/memberships/events_by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Memberships
        class EventsByClientJob < ApplicationJob
          # Step #2: trigger events for membership expirations for a Client
          # Integrations::Servicetitan::V2::Memberships::EventsByClientJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Memberships::EventsByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_membership_events_by_client').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) block_count: (Integer)
          #   (req) client_id:   (Integer)
          def perform(**args)
            super

            return unless args.dig(:block_count).to_i.positive? && args.dig(:client_id).to_i.positive? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                          (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                          (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

            st_membership_recurring_service_events = st_client.membership_recurring_service_events_export(start_at: Time.current)

            return unless st_client.success? && (client_api_integration_mrse = client_api_integration.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'membership_recurring_service_events'))

            client_api_integration_mrse.update(data: st_membership_recurring_service_events.select { |e| e if e[:active].to_bool && Chronic.parse(e[:date]) >= Time.current })

            st_membership_model_count = st_client.customer_memberships(active_only: true, status: 'Active', count_only: true)

            return unless st_client.success?

            run_at = Time.current

            (1..(st_membership_model_count.to_f / args[:block_count].to_i).ceil).each do |page|
              Integrations::Servicetitan::V2::Memberships::EventsByClientPageJob.set(wait_until: run_at).perform_later(
                block_count: args[:block_count],
                client_id:   client_api_integration.client_id,
                page:
              )

              run_at += 1.minute
            end
          end

          def max_run_time
            1200 # seconds (20 minutes)
          end
        end
      end
    end
  end
end
