# frozen_string_literal: true

# app/models/user_attachment.rb
class UserAttachment < ApplicationRecord
  belongs_to :user

  mount_uploader :image, UserMediaUploader
end
