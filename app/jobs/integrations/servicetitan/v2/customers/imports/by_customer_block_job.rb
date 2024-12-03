# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/imports/by_customer_block_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Imports
          class ByCustomerBlockJob < ApplicationJob
            # Integrations::Servicetitan::V2::Customers::Imports::ByCustomerBlockJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Imports::ByCustomerBlockJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_import_customers_by_customer_block').to_s
              @reschedule_secs  = 0
            end

            # import Contacts from ServiceTitan customers
            # step 3 / receive a block of ServiceTitan customers & create 1 DelayedJob for each customer
            # perform the ActiveJob
            #   (req) client_id:            (Integer)
            #   (req) import_criteria:      (Hash)
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
            #   (req) st_contact_models:    (Array)
            #   (req) st_customer_models:   (array)
            #   (req) st_membership_models: (Array)
            #   (req) user_id:              (Integer)
            def perform(client_id:, import_criteria:, st_contact_models:, st_customer_models:, st_membership_models:, user_id:)
              super

              return unless import_criteria.is_a?(Hash) && user_id.to_i.positive? &&
                            st_contact_models.is_a?(Array) && st_contact_models.present? && st_customer_models.is_a?(Array) && st_customer_models.present? &&
                            client_id.to_i.positive? && (client = Client.find_by(id: client_id.to_i)) &&
                            (client_api_integration = client.client_api_integrations.find_by(target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials?

              run_at = Time.current

              st_customer_models.each do |st_customer_model|
                Integrations::Servicetitan::V2::Customers::Imports::ByCustomerJob.set(wait_until: run_at).perform_later(
                  client_id:,
                  import_criteria:,
                  st_customer_model:    st_customer_model.merge(contacts: st_contact_models.map { |c| c if c[:customerId] == st_customer_model[:id] }.compact_blank),
                  st_membership_models: st_membership_models.map { |m| m[:id] == st_customer_model[:id] }.compact_blank,
                  user_id:
                )

                run_at += 1.second
              end

              st_model.import_contacts_remaining_update(user_id)
            end
          end
        end
      end
    end
  end
end
