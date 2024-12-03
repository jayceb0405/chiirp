# frozen_string_literal: true

# app/models/messages/attachment.rb
module Messages
  class Attachment < ApplicationRecord
    self.table_name = 'message_attachments'

    belongs_to :message
    belongs_to :contact_attachment, dependent: :destroy

    after_create :charge_client

    private

    # charge a Client for the image in a text message
    # after_create :charge_client
    def charge_client
      self.message.contact.client.charge_for_action(key: 'text_image_credits', contact_id: self.message.contact_id, message_id: self.message.id)
    end
  end
end
