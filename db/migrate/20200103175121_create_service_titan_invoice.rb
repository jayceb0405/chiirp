class CreateServiceTitanInvoice < ActiveRecord::Migration[5.2]
  def up
    create_table :service_titan_invoices do |t|
			t.references :contacts,          default: 0,         index: true
			t.text       :invoice_id,        default: "",        null: false
			t.datetime   :invoice_date
			t.decimal    :total,             default: 0,         null: false
			t.text       :technician_id,     default: "",        null: false
			t.text       :business_unit_id,  default: "",        null: false

			t.timestamps
    end

    add_index      :service_titan_invoices, :invoice_id
    add_index      :service_titan_invoices, :invoice_date
    add_index      :service_titan_invoices, :technician_id
    add_index      :service_titan_invoices, :business_unit_id
  end

  def down
  	drop_table :service_titan_invoices
  end
end
