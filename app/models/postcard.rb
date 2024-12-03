# frozen_string_literal: true

# app/models/postcard.rb
class Postcard < ApplicationRecord
  belongs_to :client
  belongs_to :contact
  belongs_to :tag

  validates  :target, presence: true
  validates  :card_id, presence: true
end
