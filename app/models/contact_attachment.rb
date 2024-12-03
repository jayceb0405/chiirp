# frozen_string_literal: true

# app/models/contact_attachment.rb
class ContactAttachment < ApplicationRecord
  belongs_to :contact

  has_one :message_attachment, dependent: nil, class_name: '::Messages::Attachment'

  mount_uploader :image, ContactMediaUploader
end
