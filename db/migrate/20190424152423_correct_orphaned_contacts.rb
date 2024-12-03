class CorrectOrphanedContacts < ActiveRecord::Migration[5.2]
  def change
  	Contact.all.left_outer_joins(:user).where(users: {id: nil} ).each do |c|
  		c.update(user_id: c.client.def_user_id)
  	end
  end
end
