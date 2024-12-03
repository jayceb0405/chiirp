class Add < ActiveRecord::Migration[5.2]
  def up
		add_column :contact_campaigns, :target_time, :datetime
  end

  def down
  	remove_column :contact_campaigns, :target_time
  end
end
