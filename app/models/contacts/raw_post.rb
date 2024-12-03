# frozen_string_literal: true

# app/models/contacts/raw_post.rb
module Contacts
  # Contacts::RawPost data processing
  class RawPost < ApplicationRecord
    self.table_name = 'contact_raw_posts'

    belongs_to :contact

    validates  :data, presence: true, allow_blank: true
  end
end
