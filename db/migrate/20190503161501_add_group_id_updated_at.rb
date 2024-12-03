class AddGroupIdUpdatedAt < ActiveRecord::Migration[5.2]
  def up
  	ActiveRecord::Base.record_timestamps = false
  	
  	add_column :contacts, :group_id_updated_at,  :datetime

  	Contact.where("group_id > 0").each do |c|
  		c.update(group_id_updated_at: c.updated_at)
  	end
  end

  def down
  	remove_column :contacts, :group_id_updated_at
  end
end
