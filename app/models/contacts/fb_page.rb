# frozen_string_literal: true

# app/models/contacts/fb_page.rb
module Contacts
  # Contacts::FbPage data processing
  class FbPage < ApplicationRecord
    self.table_name = 'contact_fb_pages'

    belongs_to :contact
  end
end
