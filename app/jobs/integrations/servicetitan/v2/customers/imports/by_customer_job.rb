# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/imports/by_customer_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Imports
          class ByCustomerJob < ApplicationJob
            # Integrations::Servicetitan::V2::Customers::Imports::ByCustomerJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Imports::ByCustomerJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_import_customers_by_customer').to_s
              @reschedule_secs  = 0
            end

            # import Contacts from ServiceTitan customers
            # step 4 / receive a ServiceTitan customer & import into Contact
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
            #   (req) st_customer_model:    (Hash)
            #   (req) st_membership_models: (Array)
            #   (req) user_id:              (Integer)
            def perform(client_id:, import_criteria:, st_customer_model:, st_membership_models:, user_id:)
              super

              return unless import_criteria.is_a?(Hash) && user_id.to_i.positive? && st_customer_model.is_a?(Hash) && st_customer_model.present? &&
                            client_id.to_i.positive? && (client = Client.find_by(id: client_id.to_i)) &&
                            (client_api_integration = client.client_api_integrations.find_by(target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials?

              if (import_criteria.dig(:account_0, :import).to_bool && import_criteria.dig(:account_below_0, :import).to_bool && import_criteria.dig(:account_above_0, :import).to_bool) ||
                 (import_criteria.dig(:account_0, :import).to_bool && st_customer_model.dig(:balance).to_d.zero?) ||
                 (import_criteria.dig(:account_below_0, :import).to_bool && st_customer_model.dig(:balance).to_d.negative?) ||
                 (import_criteria.dig(:account_above_0, :import).to_bool && st_customer_model.dig(:balance).to_d.positive?)

                contact = st_model.update_contact_from_customer(st_customer_model:, st_membership_models:, ignore_email_in_search: import_criteria.dig(:ignore_emails).to_bool)
                st_model.import_customers_actions(contact:, import_criteria:, st_customer_model:)
              end

              st_model.import_contacts_remaining_update(user_id)
            end
          end
        end
      end
    end
  end
end
