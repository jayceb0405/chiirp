# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/import/by_client_block_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        module Import
          class ByClientBlockJob < ApplicationJob
            # (STEP 2)
            # import existing estimates from ServiceTitan for a Client
            # Integrations::Servicetitan::V2::Estimates::Import::ByClientBlockJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Estimates::Import::ByClientBlockJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_estimate_import_by_client_block').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id:      (Integer
            #   (req) page:           (Integer)
            #   (req) page_size:      (Integer)
            #   (req) user_id:        (Integer)
            #
            #   (opt) actions:        (Hash)
            #     (opt) campaign_id:       (Integer / default: 0)
            #     (opt) group_id:          (Integer / default: 0)
            #     (opt) stage_id:          (Integer / default: 0)
            #     (opt) tag_id:            (Integer / default: 0)
            #     (opt) stop_campaign_ids: (Array of Integers / default: [])
            #   (opt) contact_id:     (Integer / default: all Contacts)
            #   (opt) orphaned_only:  (Boolean / default: false)
            #   (opt) process_events: (Boolean / default: false)
            #
            #   sent to st_client.estimates
            #     (opt) active:         (Boolean / default: true)
            #     (opt) created_at_max: (DateTime / default: nil)
            #     (opt) created_at_min: (DateTime / default: nil)
            #     (opt) status:         (String / default: nil) (open, sold, dismissed)
            #     (opt) total_max:      (Decimal / default: nil)
            #     (opt) total_min:      (Decimal / default: nil)
            #     (opt) updated_at_max: (DateTime / default: nil)
            #     (opt) updated_at_min: (DateTime / default: nil)
            def perform(**args)
              super

              return unless args.dig(:actions).is_a?(Hash) && args.dig(:client_id).to_i.positive? && args.dig(:page).to_i.positive? && args.dig(:page_size).to_i.positive? && args.dig(:user_id).to_i.positive? &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              st_estimate_models = st_client.estimates(args)

              st_job_models = []

              st_estimate_models.pluck(:jobId).in_groups_of(50, false) do |st_job_model_ids|
                st_job_models += st_client.jobs(st_job_ids: st_job_model_ids.uniq)
              end

              st_customer_models = []

              st_estimate_models.pluck(:customerId).uniq.in_groups_of(50, false) do |st_customer_model_ids|
                st_customer_models += st_client.customers(st_customer_ids: st_customer_model_ids)
              end

              st_location_models = []

              st_estimate_models.pluck(:locationId).uniq.in_groups_of(50, false) do |st_location_model_ids|
                st_location_models += st_client.locations(st_location_ids: st_location_model_ids)
              end

              contact_ids = Contact.select(contacts: { id: :id }, contact_ext_references: { ext_id: :ext_id }).joins(:ext_references).where(client_id: args[:client_id].to_i, contact_ext_references: { ext_id: st_estimate_models.pluck(:customerId) })
              run_at = Time.current

              unless args.dig(:orphaned_only).to_bool
                st_job_models.uniq.each do |st_job_model|
                  Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: run_at).perform_later(
                    actions:                        args.dig(:actions),
                    contact_id:                     contact_ids.find { |ci| ci.ext_id.to_i == st_job_model[:customerId] }&.id,
                    ok_to_process_estimate_actions: args.dig(:process_events).to_bool,
                    orphaned_estimate:              false,
                    st_customer_model:              st_customer_models.find { |cm| cm[:id] == st_job_model[:customerId] },
                    st_estimate_models:             st_estimate_models.select { |em| em[:jobId] == st_job_model[:id] },
                    st_location_model:              st_location_models.find { |lm| lm[:id] == st_job_model[:locationId] },
                    st_job_model:
                  )

                  run_at += 1.second
                end
              end

              st_estimate_models.uniq.select { |em| em[:jobId].nil? }.each do |st_estimate_model|
                Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: run_at).perform_later(
                  actions:                        args.dig(:actions),
                  contact_id:                     contact_ids.find { |ci| ci.ext_id.to_i == st_estimate_model[:customerId] }&.id,
                  ok_to_process_estimate_actions: args.dig(:process_events).to_bool,
                  orphaned_estimate:              true,
                  st_customer_model:              st_customer_models.find { |cm| cm[:id] == st_estimate_model[:customerId] },
                  st_estimate_models:             [st_estimate_model],
                  st_location_model:              st_location_models.find { |lm| lm[:id] == st_estimate_model[:locationId] }
                )

                run_at += 1.second
              end

              st_model.import_estimates_remaining_update(args[:user_id])
            end
          end
        end
      end
    end
  end
end
