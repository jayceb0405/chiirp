# frozen_string_literal: true

class DbLoader < ApplicationRecord
  validates :key, uniqueness: true, presence: true
end
