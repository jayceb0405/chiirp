class AddSettingsToClient < ActiveRecord::Migration[5.2]
  def up
		add_column :clients, :txt_msg_value, :integer, default: 0, null: false
		add_column :clients, :txt_msg_img_value, :integer, default: 0, null: false
		add_column :clients, :phone_call_value, :integer, default: 0, null: false
		add_column :clients, :rvm_value, :integer, default: 0, null: false
  end

  def down
  	remove_column :clients, :txt_msg_value
  	remove_column :clients, :txt_msg_img_value
  	remove_column :clients, :phone_call_value
  	remove_column :clients, :rvm_value
  end
end
