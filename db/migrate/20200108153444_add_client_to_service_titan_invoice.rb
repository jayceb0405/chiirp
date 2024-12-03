class AddClientToServiceTitanInvoice < ActiveRecord::Migration[5.2]
  def up
  	add_reference  :service_titan_invoices,      :client,           index: true,        null: false,        default: 0

  	ServiceTitanInvoice.all.find_each do |service_titan_invoice|
  		service_titan_invoice.update( client_id: service_titan_invoice.contact.client_id ) unless service_titan_invoice.contact.nil?
  	end
  end

  def down
  	remove_reference  :service_titan_invoices,      :client
  end
end
