class AddDashboardToCampaign < ActiveRecord::Migration[5.2]
  def up
  	add_column     :campaigns,         :dashboard,         :integer,           default: 0,         null: false
  end

  def down
  	remove_column  :campaigns,         :dashboard
  end
end
