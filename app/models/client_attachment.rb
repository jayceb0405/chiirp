# frozen_string_literal: true

# app/models/client_attachment.rb
class ClientAttachment < ApplicationRecord
  belongs_to :client

  has_one    :campaign,       dependent: nil
  has_one    :campaign_group, dependent: nil

  mount_uploader :image, ClientMediaUploader
end
