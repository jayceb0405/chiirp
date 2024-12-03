# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/customers.rb
module Integration
  module Servicetitan
    module V2
      module Customers
        module Imports
          IMPORT_PAGE_SIZE  = 5000
          IMPORT_BLOCK_SIZE = 50

          # st_model.import_customers_actions()
          #   (req) contact:           (Contact)
          #   (req) import_criteria:   (Hash)
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
          #   (req) st_customer_model: (Hash)
          def import_customers_actions(contact:, import_criteria:, st_customer_model:)
            JsonLog.info 'Integration::Servicetitan::V2::Customers::Imports.import_contact_actions', { contact:, st_customer_model:, import_criteria: }, contact_id: contact&.id
            return unless contact.is_a?(Contact) && st_customer_model.is_a?(Hash) && import_criteria.is_a?(Hash)

            # 0 balance actions
            if st_customer_model.dig(:balance).to_d.zero?
              contact.process_actions(
                campaign_id:       import_criteria.dig(:account_0, :campaign_id),
                group_id:          import_criteria.dig(:account_0, :group_id),
                stage_id:          import_criteria.dig(:account_0, :stage_id),
                tag_id:            import_criteria.dig(:account_0, :tag_id),
                stop_campaign_ids: import_criteria.dig(:account_0, :stop_campaign_ids)
              )
            end

            # balance below 0 actions
            if st_customer_model.dig(:balance).to_d.negative?
              contact.process_actions(
                campaign_id:       import_criteria.dig(:account_below_0, :campaign_id),
                group_id:          import_criteria.dig(:account_below_0, :group_id),
                stage_id:          import_criteria.dig(:account_below_0, :stage_id),
                tag_id:            import_criteria.dig(:account_below_0, :tag_id),
                stop_campaign_ids: import_criteria.dig(:account_below_0, :stop_campaign_ids)
              )
            end

            # balance above 0 actions
            return unless st_customer_model.dig(:balance).to_d.positive?

            contact.process_actions(
              campaign_id:       import_criteria.dig(:account_above_0, :campaign_id),
              group_id:          import_criteria.dig(:account_above_0, :group_id),
              stage_id:          import_criteria.dig(:account_above_0, :stage_id),
              tag_id:            import_criteria.dig(:account_above_0, :tag_id),
              stop_campaign_ids: import_criteria.dig(:account_above_0, :stop_campaign_ids)
            )
          end

          # count the number of Contacts remaining to be imported in Delayed::Job
          # st_model.import_contacts_remaining_count()
          #   (req) user_id: (Integer)
          def import_contacts_remaining_count(user_id)
            contact_count = 0

            if user_id.to_i.positive?
              if DelayedJob.where(user_id:, process: 'servicetitan_import_customers_by_client').any?
                contact_count = -1
              else
                contact_count += [0, ((DelayedJob.where(user_id:, process: 'servicetitan_import_customers_by_client_page').count - 1) * IMPORT_PAGE_SIZE)].max
                contact_count += [0, ((DelayedJob.where(user_id:, process: 'servicetitan_import_customers_by_customer_block').count - 1) * IMPORT_BLOCK_SIZE)].max
                contact_count += [0, DelayedJob.where(user_id:, process: 'servicetitan_import_customers_by_customer').count - 1].max
              end
            end

            contact_count
          end

          # return a string that may be used to inform the User how many more ServiceTitan clients are remaining in the queue to be imported
          # st_model.import_contacts_remaining_string()
          #   (req) user_id: (Integer)
          def import_contacts_remaining_string(user_id)
            remaining_count = self.import_contacts_remaining_count(user_id)

            if remaining_count.positive?
              "Contacts awaiting import: ~ #{remaining_count}"
            elsif remaining_count.negative?
              'Contacts awaiting import.'
            else
              ''
            end
          end

          # update contact_imports_remaining_count element showing remaining ServiceTitan clients to import
          # st_model.import_contacts_remaining_update()
          #   (req) user_id:     (Integer)
          def import_contacts_remaining_update(user_id)
            current_logger_level = Rails.logger.level
            Rails.logger.level = :error

            if user_id.to_i.positive? && (user = User.find_by(id: user_id))
              UserCable.new.broadcast(user.client, user, { append: 'false', id: 'contact_imports_remaining_count', html: self.import_contacts_remaining_string(user_id) })
            end

            Rails.logger.level = current_logger_level
          end
        end
      end
    end
  end
end
