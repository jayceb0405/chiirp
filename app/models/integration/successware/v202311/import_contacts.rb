# frozen_string_literal: true

# app/models/integration/successware/v202311/import_contacts.rb
module Integration
  module Successware
    module V202311
      module ImportContacts
        IMPORT_BLOCK_COUNT = 50

        # sw_model.import_contact_actions()
        #   (req) contact:         (Contact)
        #   (req) actions:         (Hash)
        #     (opt) above_0: (Hash)
        #       (opt) import:            (Boolean)
        #       (opt) campaign_id:       (Integer)
        #       (opt) group_id:          (Integer)
        #       (opt) stage_id:          (Integer)
        #       (opt) tag_id:            (Integer)
        #       (opt) stop_campaign_ids: (Array)
        #     (opt) eq_0: (Hash)
        #       (opt) import:            (Boolean)
        #       (opt) campaign_id:       (Integer)
        #       (opt) group_id:          (Integer)
        #       (opt) stage_id:          (Integer)
        #       (opt) tag_id:            (Integer)
        #       (opt) stop_campaign_ids: (Array)
        #     (opt) below_0: (Hash)
        #       (opt) import:            (Boolean)
        #       (opt) campaign_id:       (Integer)
        #       (opt) group_id:          (Integer)
        #       (opt) stage_id:          (Integer)
        #       (opt) tag_id:            (Integer)
        #       (opt) stop_campaign_ids: (Array)
        #   (req) account_balance: (BigDecimal)
        def import_contact_actions(contact, actions, account_balance)
          JsonLog.info 'Integration::Successware::V202311::ImportContacts.import_contact_actions', { account_balance:, actions:, contact: }, client_id: @client.id
          return unless actions.is_a?(Hash) && contact.is_a?(Contact)

          # 0 balance actions
          if account_balance.to_d.zero?
            contact.process_actions(
              campaign_id:       actions.dig(:eq_0, :campaign_id).to_i,
              group_id:          actions.dig(:eq_0, :group_id).to_i,
              stage_id:          actions.dig(:eq_0, :stage_id).to_i,
              tag_id:            actions.dig(:eq_0, :tag_id).to_i,
              stop_campaign_ids: actions.dig(:eq_0, :stop_campaign_ids)
            )
          end

          # balance below 0 actions
          if account_balance.to_d.negative?
            contact.process_actions(
              campaign_id:       actions.dig(:below_0, :campaign_id).to_i,
              group_id:          actions.dig(:below_0, :group_id).to_i,
              stage_id:          actions.dig(:below_0, :stage_id).to_i,
              tag_id:            actions.dig(:below_0, :tag_id).to_i,
              stop_campaign_ids: actions.dig(:below_0, :stop_campaign_ids)
            )
          end

          # balance above 0 actions
          return unless account_balance.to_d.positive?

          contact.process_actions(
            campaign_id:       actions.dig(:above_0, :campaign_id).to_i,
            group_id:          actions.dig(:above_0, :group_id).to_i,
            stage_id:          actions.dig(:above_0, :stage_id).to_i,
            tag_id:            actions.dig(:above_0, :tag_id).to_i,
            stop_campaign_ids: actions.dig(:above_0, :stop_campaign_ids)
          )
        end

        # count the number of Contacts remaining to be imported in Delayed::Job
        # sw_model.import_contacts_remaining_count()
        #   (req) user_id: (Integer)
        def import_contacts_remaining_count(user_id)
          contact_count = 0

          if user_id.to_i.positive?
            contact_count += [0, ((DelayedJob.where(user_id:, process: %w[successware_import_contacts successware_import_contacts_blocks]).count - 1) * IMPORT_BLOCK_COUNT)].max
            contact_count += [0, DelayedJob.where(user_id:, process: 'successware_import_contact').count - 1].max
          end

          contact_count
        end

        # return a string that may be used to inform the User how many more Successware clients are remaining in the queue to be imported
        # sw_model.import_contacts_remaining_string()
        #   (req) user_id: (Integer)
        def import_contacts_remaining_string(user_id)
          remaining_count = self.import_contacts_remaining_count(user_id)

          if remaining_count.positive?
            "Contacts awaiting import: ~ #{remaining_count}"
          else
            ''
          end
        end

        # update contact_imports_remaining_count element showing remaining Successware clients to import
        # sw_model.import_contacts_remaining_update()
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
