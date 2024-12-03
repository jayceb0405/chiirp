class ServiceTitanInvoiceJobs < ActiveRecord::Migration[5.2]
  def up
  	rename_column  :service_titan_invoices,      :job_id,            :job_type_id
		add_column     :service_titan_invoices,      :job_id,            :string,            null: false,        default: ""

		ServiceTitanInvoice.find_each do |service_titan_invoice|
			service_titan_invoice.delay( priority: 9, process: "update_job_id_from_job_type_id" ).temp_update_job_id_from_job_type_id
		end
  end

  def down
		remove_column  :service_titan_invoices,      :job_id
  	rename_column  :service_titan_invoices,      :job_type_id,       :job_id
  end
end
