class AddIndexesToServiceTitanInvoices < ActiveRecord::Migration[5.2]
  def up
  	add_index :service_titan_invoices, :job_id
  	add_index :service_titan_invoices, :review
  	add_index :service_titan_invoices, :total
  end

  def down
  	remove_index :service_titan_invoices, :job_id
  	remove_index :service_titan_invoices, :review
  	remove_index :service_titan_invoices, :total
  end
end
