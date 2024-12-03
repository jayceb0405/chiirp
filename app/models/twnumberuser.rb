# frozen_string_literal: true

# app/models/twnumberuser.rb
class Twnumberuser < ApplicationRecord
  belongs_to :user
  belongs_to :twnumber

  scope :with_user_name, -> {
    joins(:user)
      .select(:id, :user_id, :twnumber_id, :def_user, :created_at, :updated_at, 'users.lastname AS lastname', 'users.firstname AS firstname')
      .order(:lastname, :firstname)
  }
end
