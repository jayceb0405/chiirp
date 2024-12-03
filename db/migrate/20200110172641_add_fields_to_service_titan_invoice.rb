class AddFieldsToServiceTitanInvoice < ActiveRecord::Migration[5.2]
  def up
		add_column     :service_titan_invoices,      :estimates_total,   :decimal,           null: false,        default: 0
		add_column     :service_titan_invoices,      :tech_lead_id,      :text,              null: false,        default: ""
		add_column     :service_titan_invoices,      :recall_id,         :text,              null: false,        default: ""
  end

  def down
		remove_column  :service_titan_invoices,      :estimates_total
		remove_column  :service_titan_invoices,      :tech_lead_id
		remove_column  :service_titan_invoices,      :recall_id
  end
end
