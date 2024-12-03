class AddReviewToServiceTitanInvoice < ActiveRecord::Migration[5.2]
  def up
  	add_column     :service_titan_invoices,      :review,            :integer,           null: true,         default: nil,       index: true
  end

  def down
		remove_column  :service_titan_invoices,      :review
  end
end
