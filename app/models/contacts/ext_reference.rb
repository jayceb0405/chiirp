# frozen_string_literal: true

# app/models/contacts/ext_reference.rb
module Contacts
  # Contacts::ExtReference data processing
  class ExtReference < ApplicationRecord
    self.table_name = 'contact_ext_references'

    belongs_to :contact

    # Return a list of available ext reference targets
    def self.targets
      self.group(:target).distinct.pluck(:target)
    end
  end
end
