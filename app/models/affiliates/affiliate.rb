# frozen_string_literal: true

# app/models/affiliates/affiliate.rb
module Affiliates
  class Affiliate < ApplicationRecord
    has_many :clients,  dependent: nil
    has_many :packages, dependent: nil

    validates :company_name, presence: true, length: { minimum: 2 }, uniqueness: true

    after_initialize :apply_defaults, if: :new_record?

    def initials
      self.company_name.split.pluck(0).join
    end

    private

    def apply_defaults
      self.company_name ||= 'New Affiliate'
    end
  end
end
