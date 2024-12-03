# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/imports/by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Imports
          class ByClientJob < ApplicationJob
            # Integrations::Servicetitan::V2::Customers::Imports::ByClientJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Imports::ByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_import_customers_by_client').to_s
              @reschedule_secs  = 0
            end

            # import Contacts from ServiceTitan customers
            # step 1 / get the ServiceTitan customer count and create 1 DelayedJob for every IMPORT_PAGE_SIZE
            # perform the ActiveJob
            #   (req) client_id:       (Integer)
            #   (req) import_criteria: (Hash)
            #     (opt) active_only:       (Boolean / default: true)
            #     (opt) account_0:         (Hash)
            #       (opt) import:            (Boolean / default: true)
            #       (opt) campaign_id:       (Integer)
            #       (opt) group_id:          (Integer)
            #       (opt) stage_id:          (Integer)
            #       (opt) stop_campaign_ids: (Array)
            #       (opt) tag_id:            (Integer)
            #     (opt) account_above_0:   (Hash)
            #       (opt) import:            (Boolean / default: true)
            #       (opt) campaign_id:       (Integer)
            #       (opt) group_id:          (Integer)
            #       (opt) stage_id:          (Integer)
            #       (opt) stop_campaign_ids: (Array)
            #       (opt) tag_id:            (Integer)
            #     (opt) account_below_0:   (Hash)
            #       (opt) import:            (Boolean / default: true)
            #       (opt) campaign_id:       (Integer)
            #       (opt) group_id:          (Integer)
            #       (opt) stage_id:          (Integer)
            #       (opt) stop_campaign_ids: (Array)
            #       (opt) tag_id:            (Integer)
            #     (opt) created_after:     (DateTime / UTC)
            #     (opt) created_before:    (DateTime / UTC)
            #     (opt) ignore_emails:     (Boolean / default: false)
            #   (req) user_id:         (Integer)
            def perform(client_id:, import_criteria:, user_id:)
              super

              return unless import_criteria.is_a?(Hash) && user_id.to_i.positive? &&
                            client_id.to_i.positive? && (client = Client.find_by(id: client_id.to_i)) &&
                            (client_api_integration = client.client_api_integrations.find_by(target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              customer_count = st_client.customer_count(active: import_criteria.dig(:active_only), created_after: import_criteria.dig(:created_after), created_before: import_criteria.dig(:created_before))
              run_at = Time.current

              (1..(customer_count.to_f / Integration::Servicetitan::V2::Customers::Imports::IMPORT_PAGE_SIZE).ceil).each do |page|
                Integrations::Servicetitan::V2::Customers::Imports::ByClientPageJob.set(wait_until: run_at).perform_later(
                  client_id:,
                  import_criteria:,
                  page:,
                  user_id:
                )

                run_at += 10.minutes
              end

              st_model.import_contacts_remaining_update(user_id)
            end
          end
        end
      end
    end
  end
end
