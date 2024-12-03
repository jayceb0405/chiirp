class AddInvoiceIdToContactJob < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding invoice_id to Contacts::Job table...' do
      add_column :contact_jobs, :ext_invoice_id, :string
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
