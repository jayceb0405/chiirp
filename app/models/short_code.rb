# frozen_string_literal: true

# app/models/short_code.rb
class ShortCode < ApplicationRecord
  belongs_to :client

  validates :code, uniqueness: true
  validates :code, :url, presence: true

  before_validation :ensure_code_exists

  def self.generate_code
    RandomCode.new.create(20)
  end

  def host
    Rails.env.production? ? 'chiirppay.com' : 'ian-dev.chiirp.com'
  end

  def to_s
    Rails.application.routes.url_helpers.short_code_url(self, host:)
  end

  def to_param
    code
  end

  private

  def ensure_code_exists
    self.code = ShortCode.generate_code unless code
  end
end
