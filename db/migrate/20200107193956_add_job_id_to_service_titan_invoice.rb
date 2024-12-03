class AddJobIdToServiceTitanInvoice < ActiveRecord::Migration[5.2]
  def up
		add_column     :service_titan_invoices,      :job_id,            :string,            null: false,        default: ""
  end

  def down
		remove_column  :service_titan_invoices,      :job_id
  end
end
