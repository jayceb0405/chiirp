# frozen_string_literal: true

# app/models/messages/email.rb
module Messages
  class Email < ApplicationRecord
    self.table_name = 'message_emails'

    belongs_to :message

    has_many_attached :images

    store_accessor :data, :bcc_emails, :cc_emails, :to_emails

    after_initialize :apply_defaults, if: :new_record?

    private

    def apply_defaults
      self.bcc_emails     ||= []
      self.cc_emails      ||= []
      self.to_emails      ||= []
    end
  end
end
