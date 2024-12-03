# frozen_string_literal: true

# app/models/integration/fieldpulse/v1/import_contacts.rb
module Integration
  module Fieldpulse
    module V1
      module ImportContacts
        # count the number of Contacts remaining to be imported in Delayed::Job
        # fr_model.import_contacts_remaining_count()
        #   (req) user_id: (Integer)
        def import_contacts_remaining_count(user_id)
          contact_count = 0

          if user_id.to_i.positive?
            contact_count += [0, ((Delayed::Job.where(process: 'fieldpulse_import_contacts_blocks', user_id:).count - 1) * Integrations::FieldPulse::V1::Base::IMPORT_BLOCK_COUNT)].max
            contact_count += [0, Delayed::Job.where(process: 'fieldpulse_import_contact', user_id:).count - 1].max
          end

          contact_count
        end

        # return a string that may be used to inform the User how many more Fieldpulse customers are remaining in the queue to be imported
        # fr_model.import_contacts_remaining_string()
        #   (req) user_id: (Integer)
        # rubocop:disable Style/OptionalBooleanParameter
        def import_contacts_remaining_string(user_id, count_fieldpulse_import_contacts = true)
          if count_fieldpulse_import_contacts && Delayed::Job.where(process: 'fieldpulse_import_contacts', user_id:).any?
            'Contact imports queued.'
          else
            remaining_count = self.import_contacts_remaining_count(user_id)

            if remaining_count.positive?
              "Contacts awaiting import: ~ #{remaining_count}"
            else
              ''
            end
          end
        end
        # rubocop:enable Style/OptionalBooleanParameter

        # update contact_imports_remaining_count element showing remaining Fieldpulse customers to import
        # fr_model.import_contacts_remaining_update()
        #   (req) user_id: (Integer)
        # rubocop:disable Style/OptionalBooleanParameter
        def import_contacts_remaining_update(user_id, count_fieldpulse_import_contacts = true)
          current_logger_level = Rails.logger.level
          Rails.logger.level = :error

          if user_id.to_i.positive? && (user = User.find_by(id: user_id))
            UserCable.new.broadcast(user.client, user, { append: 'false', id: 'contact_imports_remaining_count', html: self.import_contacts_remaining_string(user_id, count_fieldpulse_import_contacts) })
          end

          Rails.logger.level = current_logger_level
        end
        # rubocop:enable Style/OptionalBooleanParameter
      end
    end
  end
end
