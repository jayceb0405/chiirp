# frozen_string_literal: true

# app/models/contacts/note.rb
module Contacts
  class Note < ApplicationRecord
    self.table_name = 'contact_notes'

    belongs_to :contact
    belongs_to :user

    private

    def after_create_commit_actions
      super

      self.contact.send_to_zapier(action: 'receive_updated_contact')

      Integrations::Servicetitan::V2::SendNoteAsNote.perform_later(
        contact_note_id: self.id,
        contact_id:      self.contact_id,
        user_id:         self.contact.user_id
      )
    end

    def after_update_commit_actions
      super

      self.contact.send_to_zapier(action: 'receive_updated_contact') if self.previous_changes.present?
    end
  end
end
