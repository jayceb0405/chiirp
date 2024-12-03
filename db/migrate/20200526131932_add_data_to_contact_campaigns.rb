class AddDataToContactCampaigns < ActiveRecord::Migration[5.2]
  def up
  	add_column     :contact_campaigns, :data,              :text,              null: false,        default: {}.to_yaml
  end

  def down
  	remove_column  :contact_campaigns, :data
  end
end
