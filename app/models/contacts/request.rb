# frozen_string_literal: true

# app/models/contacts/request.rb
module Contacts
  class Request < ApplicationRecord
    self.table_name = 'contact_requests'

    belongs_to :contact

    validates :ext_id, :ext_source, :status, presence: true, allow_blank: true
  end
end
