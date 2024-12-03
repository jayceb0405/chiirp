# frozen_string_literal: true

# app/models/messages/folder_assignment.rb
module Messages
  class FolderAssignment < ApplicationRecord
    self.table_name = 'message_folder_assignments'

    belongs_to :message
    belongs_to :folder

    # rubocop:disable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
    validates :folder, uniqueness: { scope: :message, message: 'may only be applied once per Message' }
    # rubocop:enable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
  end
end
