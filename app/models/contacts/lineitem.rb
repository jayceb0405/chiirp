# frozen_string_literal: true

# app/models/contacts/lineitem.rb
module Contacts
  # Contacts::Lineitem data processing
  class Lineitem < ApplicationRecord
    self.table_name = 'contact_lineitems'

    belongs_to :lineitemable, polymorphic: true
  end
end
