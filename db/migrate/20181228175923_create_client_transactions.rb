class CreateClientTransactions < ActiveRecord::Migration[5.2]
  def up
  	add_column :clients, :settings, :text

  	Client.all.each do |c|
  		c.update(settings: {
  			unlimited: c.unlimited.to_i,
  			auto_recharge: c.auto_recharge.to_i,
  			auto_min_amount: c.auto_min_amount.to_i,
  			auto_add_amount: c.auto_add_amount.to_i,
  			s211: c.txt_msg_value.to_f / 100,
  			s212: c.txt_msg_img_value.to_f / 100,
  			s231: c.phone_call_value.to_f / 100,
  			s232: c.rvm_value.to_f / 100
  		})
  	end

  	remove_column :clients, :unlimited
  	remove_column :clients, :auto_recharge
  	remove_column :clients, :auto_min_amount
  	remove_column :clients, :auto_add_amount
  	remove_column :clients, :txt_msg_value
  	remove_column :clients, :txt_msg_img_value
  	remove_column :clients, :phone_call_value
  	remove_column :clients, :rvm_value

    create_table :client_transactions do |t|
      t.references :client, foreign_key: true
      t.string :setting_key, default: "", null: false
      t.string :setting_value, default: "", null: false

			t.timestamps
    end
  end

  def down
  	drop_table :client_transactions

		add_column :clients, :unlimited, :integer, default: 0, null: false
		add_column :clients, :auto_recharge, :integer, default: 0, null: false
		add_column :clients, :auto_min_amount, :integer, default: 0, null: false
		add_column :clients, :auto_add_amount, :integer, default: 0, null: false
		add_column :clients, :txt_msg_value, :integer, default: 0, null: false
		add_column :clients, :txt_msg_img_value, :integer, default: 0, null: false
		add_column :clients, :phone_call_value, :integer, default: 0, null: false
		add_column :clients, :rvm_value, :integer, default: 0, null: false

  	Client.all.each do |c|
  		c.update(unlimited: c.settings[:unlimited].to_i,
  			auto_recharge: c.settings[:auto_recharge].to_i,
  			auto_min_amount: c.settings[:auto_min_amount].to_i,
  			auto_add_amount: c.settings[:auto_add_amount].to_i,
  			txt_msg_value: (c.settings[:s211].to_f * 100).to_i,
  			txt_msg_img_value: (c.settings[:s212].to_f * 100).to_i,
  			phone_call_value: (c.settings[:s231].to_f * 100).to_i,
  			rvm_value: (c.settings[:s232].to_f * 100).to_i
  		)
  	end

  	remove_column :clients, :settings
  end
end
