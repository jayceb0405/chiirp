class AddDefaultPhoneToCampaign < ActiveRecord::Migration[5.2]
  def up
  	add_column :campaigns, :default_phone, :string, default: ""
  end

  def down
  	remove_column :campaigns, :default_phone
  end
end
