# frozen_string_literal: true

# app/models/fcp_invoice.rb
class FcpInvoice < ApplicationRecord
  belongs_to       :client
  belongs_to       :contact

  scope :unique_business_units_by_date_range, ->(client_id, start_time, end_time) {
    where(client_id:)
      .where(invoice_date: [start_time..end_time])
      .pluck(:business_unit_id)
      .uniq
  }
  scope :unique_job_types_by_date_range, ->(client_id, start_time, end_time) {
    where(client_id:)
      .where(invoice_date: [start_time..end_time])
      .pluck(:job_type_id)
      .uniq
  }
  scope :unique_technicians_by_date_range, ->(client_id, start_time, end_time) {
    where(client_id:)
      .where(invoice_date: [start_time..end_time])
      .pluck(:ext_tech_id)
      .uniq
  }
  scope :by_date_range, ->(client_id, start_time, end_time) {
    where(client_id:)
      .where(invoice_date: [start_time..end_time])
  }
end
