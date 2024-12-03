class RemoveClientBillingInfo < ActiveRecord::Migration[5.2]
  def up
		remove_column :clients, :billing_name
		remove_column :clients, :billing_address1
		remove_column :clients, :billing_address2
		remove_column :clients, :billing_city
		remove_column :clients, :billing_state
		remove_column :clients, :billing_zip
		remove_column :clients, :billing_phone

		add_column :client_transactions, :data, :text, default: ""
  end

  def down
		add_column :clients, :billing_name, :string, default: ""
		add_column :clients, :billing_address1, :string, default: ""
		add_column :clients, :billing_address2, :string, default: ""
		add_column :clients, :billing_city, :string, default: ""
		add_column :clients, :billing_state, :string, default: ""
		add_column :clients, :billing_zip, :string, default: ""
		add_column :clients, :billing_phone, :string, default: ""

		remove_column :client_transactions, :data
  end
end
