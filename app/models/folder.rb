# frozen_string_literal: true

# app/models/folder.rb
class Folder < ApplicationRecord
  belongs_to :client

  has_many   :folder_assignments, dependent: :delete_all, class_name: '::Messages::FolderAssignment'
  has_many   :messages, through: :folder_assignments

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates  :name, presence: true, length: { minimum: 1 }, uniqueness: { scope: [:client_id] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  def self.title
    I18n.t('activerecord.models.folder.title')
  end
end
