class CreateClientBilling < ActiveRecord::Migration[5.2]
	def up
		add_column :clients, :billing_name, :string, default: ""
		add_column :clients, :billing_address1, :string, default: ""
		add_column :clients, :billing_address2, :string, default: ""
		add_column :clients, :billing_city, :string, default: ""
		add_column :clients, :billing_state, :string, default: ""
		add_column :clients, :billing_zip, :string, default: ""
		add_column :clients, :billing_phone, :string, default: ""
		add_column :clients, :unlimited, :integer, default: 0, null: false
		add_column :clients, :auto_recharge, :integer, default: 0, null: false
		add_column :clients, :auto_min_amount, :integer, default: 0, null: false
		add_column :clients, :auto_add_amount, :integer, default: 0, null: false
		add_column :clients, :current_balance, :integer, default: 0, null: false

		add_column :twmessages, :automated, :integer, default: 0, null: false

		Twmessage.where.not(triggeraction_id: nil).update_all(automated: 1)

		create_table :system_settings do |t|
			t.datetime :start_date, index: true
			t.datetime :end_date, index: true
			t.string   :setting_key, default: "", index: true
			t.integer  :setting_value, default: 0, null: false

			t.timestamps
		end
	end

	def down
		remove_column :clients, :billing_name
		remove_column :clients, :billing_address1
		remove_column :clients, :billing_address2
		remove_column :clients, :billing_city
		remove_column :clients, :billing_state
		remove_column :clients, :billing_zip
		remove_column :clients, :billing_phone
		remove_column :clients, :unlimited
		remove_column :clients, :auto_recharge
		remove_column :clients, :auto_min_amount
		remove_column :clients, :auto_add_amount
		remove_column :clients, :current_balance

		remove_column :twmessages, :automated

		drop_table :system_settings
	end
end
