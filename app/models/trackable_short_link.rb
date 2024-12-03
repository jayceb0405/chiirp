# frozen_string_literal: true

# app/models/trackable_short_link.rb
class TrackableShortLink < ApplicationRecord
  belongs_to :trackable_link
  belongs_to :contact

  has_many :trackable_links_hits, dependent: :delete_all

  before_create :generate_short_code

  def generate_short_code(len = 6)
    self.short_code = RandomCode.new.create(len)
    self.short_code = RandomCode.new.create(len) while TrackableShortLink.find_by_short_code(self.short_code)
  end
end
