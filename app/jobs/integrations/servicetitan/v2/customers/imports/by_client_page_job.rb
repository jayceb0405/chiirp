# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/imports/by_client_page_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Imports
          class ByClientPageJob < ApplicationJob
            # Integrations::Servicetitan::V2::Customers::Imports::ByClientPageJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Imports::ByClientPageJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_import_customers_by_client_page').to_s
              @reschedule_secs  = 0
            end

            # import Contacts from ServiceTitan customers
            # step 2 / get the ServiceTitan customers for a defined IMPORT_PAGE_SIZE & create 1 DelayedJob for each (IMPORT_BLOCK_SIZE)
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
            #   (req) page:            (Integer)
            #   (req) user_id:         (Integer)
            def perform(client_id:, import_criteria:, page:, user_id:)
              super

              return unless import_criteria.is_a?(Hash) && page.to_i.positive? && user_id.to_i.positive? &&
                            client_id.to_i.positive? && (client = Client.find_by(id: client_id.to_i)) &&
                            (client_api_integration = client.client_api_integrations.find_by(target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              st_customer_models = st_client.customers(
                active:         import_criteria.dig(:active_only),
                created_after:  import_criteria.dig(:created_after),
                created_before: import_criteria.dig(:created_before),
                page:           page.to_i,
                page_size:      Integration::Servicetitan::V2::Customers::Imports::IMPORT_PAGE_SIZE
              )
              st_contact_models = st_client.customers_contacts(
                st_customer_ids: st_customer_models.pluck(:id),
                page_size:       Integration::Servicetitan::V2::Customers::Imports::IMPORT_PAGE_SIZE
              )
              st_membership_models = st_client.customer_memberships(
                active_only:     true,
                status:          'Active',
                st_customer_ids: st_customer_models.pluck(:id),
                page_size:       Integration::Servicetitan::V2::Customers::Imports::IMPORT_PAGE_SIZE
              )
              run_at = Time.current

              st_customer_models.in_groups_of(Integration::Servicetitan::V2::Customers::Imports::IMPORT_BLOCK_SIZE, false).each do |st_customer_models_block|
                Integrations::Servicetitan::V2::Customers::Imports::ByCustomerBlockJob.set(wait_until: run_at).perform_later(
                  client_id:,
                  import_criteria:,
                  st_contact_models:    st_contact_models.map { |c| c if st_customer_models_block.pluck(:id).include?(c[:customerId]) }.compact_blank,
                  st_customer_models:   st_customer_models_block,
                  st_membership_models: st_membership_models.map { |c| c if st_customer_models_block.pluck(:id).include?(c[:customerId]) }.compact_blank,
                  user_id:
                )

                run_at += Integration::Servicetitan::V2::Customers::Imports::IMPORT_BLOCK_SIZE.seconds
              end

              st_model.import_contacts_remaining_update(user_id)
            end
          end
        end
      end
    end
  end
end
