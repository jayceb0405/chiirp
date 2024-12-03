# frozen_string_literal: true

# app/models/review.rb
class Review < ApplicationRecord
  belongs_to :client
  belongs_to :contact, optional: true

  validates  :name, presence: true
  validates  :review_id, presence: true
  validates  :star_rating, numericality: { in: 0..5 }

  scope :unread_reviews_by_client, ->(client_id) {
    select('reviews.*')
      .where(read_at: nil)
      .where(client_id:)
  }
  scope :unread_reviews_by_contact, ->(contact_id) {
    select('reviews.*')
      .where(read_at: nil)
      .where(contact_id:)
  }
  scope :unread_reviews_by_user, ->(user_id) {
    select('reviews.*')
      .where(read_at: nil)
      .joins(:contact)
      .where(contacts: { user_id: })
  }
end
