# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/import/orphaned/by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        module Import
          module Orphaned
            class ByClientJob < ApplicationJob
              # Integrations::Servicetitan::V2::Estimates::Import::Orphaned::ByClientJob.set(wait_until: 1.day.from_now).perform_later()
              # Integrations::Servicetitan::V2::Estimates::Import::Orphaned::ByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

              def initialize(**args)
                super

                @process          = (args.dig(:process).presence || 'servicetitan_import_orphaned_estimates_by_client').to_s
                @reschedule_secs  = 0
              end

              # import orphaned estimates from ServiceTitan
              #   (req) client_id:      (Integer)
              #   (req) created_at_max: (DateTime)
              #   (req) created_at_min: (DateTime)
              def perform(**args)
                super

                return unless args.dig(:client_id).to_i.positive? &&
                              args.dig(:created_at_min).respond_to?(:strftime) && args.dig(:created_at_max).respond_to?(:strftime) && args[:created_at_min] < args[:created_at_max] &&
                              (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                              (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                              (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

                st_estimate_models = st_client.estimates(active: true, created_at_min: args[:created_at_min], created_at_max: args[:created_at_max])
                st_customer_models = []

                st_estimate_models.pluck(:customerId).uniq.in_groups_of(50, false) do |st_customer_model_ids|
                  st_customer_models += st_client.customers(st_customer_ids: st_customer_model_ids)
                end

                st_location_models = []

                st_estimate_models.pluck(:locationId).uniq.in_groups_of(50, false) do |st_location_model_ids|
                  st_location_models += st_client.locations(st_location_ids: st_location_model_ids)
                end

                st_membership_models = st_client.customer_memberships(active_only: true, status: 'Active', st_customer_ids: st_estimate_models.pluck(:customerId).uniq)

                run_at = Time.current

                st_estimate_models.select { |e| e.dig(:jobId).to_i.zero? }.each do |st_estimate_model|
                  contact = st_model.update_contact_from_customer(st_customer_model: st_customer_models.find { |cm| cm[:id] == st_estimate_model[:customerId] }, st_membership_models: st_membership_models.select { |m| m[:customerId] == st_estimate_model[:customerId] })

                  if contact.is_a?(Contact)
                    Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: run_at).perform_later(
                      contact_id:                     contact.id,
                      ok_to_process_estimate_actions: true,
                      orphaned_estimate:              true,
                      st_customer_model:              st_customer_models.find { |cm| cm[:id] == st_estimate_model[:customerId] },
                      st_estimate_models:             [st_estimate_model],
                      st_location_model:              st_location_models.find { |lm| lm[:id] == st_estimate_model[:locationId] }
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
  end
end
