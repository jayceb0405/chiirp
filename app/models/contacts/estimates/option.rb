# frozen_string_literal: true

# app/models/contacts/estimates/option.rb
module Contacts
  module Estimates
    # Contacts::Estimates::Option data processing
    class Option < ApplicationRecord
      self.table_name = 'contact_estimate_options'

      belongs_to :estimate, class_name: '::Contacts::Estimate'

      validates  :name, :status, :option_number, :notes, :message, :ext_source, :ext_id, presence: true, allow_blank: true
      validates  :total_amount, numericality: true
    end
  end
end
