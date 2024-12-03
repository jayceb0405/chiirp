class CreateContactInvoiceAgain < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Contacts::Invoices...' do
      create_table :contact_invoices do |t|
        t.references :contact, foreign_key: true, index: true
        t.references :job, foreign_key: { to_table: :contact_jobs }, index: true
        t.string     :ext_source
        t.string     :ext_id, index: true
        t.string     :invoice_number, index: true
        t.string     :description
        t.string     :customer_type
        t.string     :status
        t.decimal    :total_amount
        t.decimal    :total_payments
        t.decimal    :balance_due
        t.datetime   :due_date
        t.integer    :net

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
