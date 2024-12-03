# frozen_string_literal: true

# app/models/clients/note.rb
module Clients
  class Note < ApplicationRecord
    self.table_name = 'client_notes'

    belongs_to :client
    belongs_to :user

    def after_create_commit_actions
      super

      Integration::Vitally::V2024::Base.new.note_push(self.id) if self.client.ok_to_push_to_vitally?
    end

    def after_update_commit_actions
      super

      Integration::Vitally::V2024::Base.new.note_push(self.id) if self.client.ok_to_push_to_vitally?
    end
  end
end
