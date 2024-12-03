# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/import/by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        module Import
          class ByClientJob < ApplicationJob
            # (STEP 1)
            # import existing estimates from ServiceTitan for a Client
            # Integrations::Servicetitan::V2::Estimates::Import::ByClientJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Estimates::Import::ByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_estimate_import_by_client').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id:      (Integer)
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
            #   sent to st_client.estimate_count
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

              return unless args.dig(:actions).is_a?(Hash) && args.dig(:client_id).to_i.positive? && args.dig(:user_id).to_i.positive? &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              return if args.dig(:contact_id).to_i.positive?

              estimate_count = st_client.estimate_count(args)
              page_size      = 50
              run_at         = Time.current

              (1..(estimate_count.to_f / page_size).ceil).each do |page|
                Integrations::Servicetitan::V2::Estimates::Import::ByClientBlockJob.set(wait_until: run_at).perform_later(**args.merge({ page:, page_size: }))

                run_at += 5.seconds
              end

              st_model.import_estimates_remaining_update(args[:user_id])
            end
          end
        end
      end
    end
  end
end
