# frozen_string_literal: true

# app/models/contacts/job.rb
module Contacts
  class Subscription < ApplicationRecord
    self.table_name = 'contact_subscriptions'

    belongs_to :contact

    validates  :ext_source, :ext_id, :customer_id, presence: true, allow_blank: false
    validates  :total, :total_due, numericality: true

    # replace Tags in message content with Contacts::Subscription data
    # content = contact_subscription.message_tag_replace(String)
    def message_tag_replace(message)
      # rubocop:disable Lint/InterpolationCheck
      message.to_s
             .gsub('#{subscription-status}', self.status)
             .gsub('#{subscription-firstname}', self.firstname)
             .gsub('#{subscription-lastname}', self.lastname)
             .gsub('#{subscription-fullname}', Friendly.new.fullname(self.firstname, self.lastname))
             .gsub('#{subscription-companyname}', self.companyname)
             .gsub('#{subscription-total}', ActionController::Base.helpers.number_to_currency(self.total.to_d))
             .gsub('#{subscription-total_due}', ActionController::Base.helpers.number_to_currency(self.total_due.to_d))
             .gsub('#{subscription-description}', self.description)
      # rubocop:enable Lint/InterpolationCheck
    end
  end
end
