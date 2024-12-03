# frozen_string_literal: true

# app/models/contacts/ggl_conversation.rb
module Contacts
  # Contacts::GglConversation data processing
  class GglConversation < ApplicationRecord
    self.table_name = 'contact_ggl_conversations'

    belongs_to :contact
  end
end
