# frozen_string_literal: true

# app/models/contacts/invoice.rb
module Contacts
  class Invoice < ApplicationRecord
    self.table_name = 'contact_invoices'

    belongs_to :contact
    belongs_to :job, class_name: '::Contacts::Job', optional: true

    has_many :lineitems, as: :lineitemable, dependent: :delete_all, class_name: '::Contacts::Lineitem'

    validates :ext_id, :ext_source, :status, presence: true
    validates :total_amount, :total_payments, :balance_due, numericality: true
    validates :net, numericality: { only_integer: true }

    # replace Tags in message content with Contacts::Invoice data
    # content = contact_estimate.message_tag_replace(String)
    def message_tag_replace(message)
      # rubocop:disable Lint/InterpolationCheck
      message.to_s
             .gsub('#{invoice-invoice_number}', self.invoice_number)
             .gsub('#{invoice-net}', self.net.to_s)
             .gsub('#{invoice-status}', self.status)
             .gsub('#{invoice-subject}', self.description)
             .gsub('#{invoice-total_amount}', ActionController::Base.helpers.number_to_currency(self.total_amount.to_d))
             .gsub('#{invoice-total_payments}', ActionController::Base.helpers.number_to_currency(self.total_payments.to_d))
             .gsub('#{invoice-balance_due}', ActionController::Base.helpers.number_to_currency(self.balance_due.to_d))
             .gsub('#{invoice-due_date}', self.due_date&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
      # rubocop:enable Lint/InterpolationCheck
    end
  end
end
