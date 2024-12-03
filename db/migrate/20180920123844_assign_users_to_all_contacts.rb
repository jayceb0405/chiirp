class AssignUsersToAllContacts < ActiveRecord::Migration[5.2]
  def up
    add_reference :clients, :def_user, references: :users, index: true
    add_foreign_key :clients, :users, column: :def_user_id

  	Client.all.each do |c|
  		# scan through each Client

  		if c.update_def_user_id []
				# find all unassigned Contacts
				unassigned_contacts = c.contacts.where(user_id: [nil, 0])

				# assign unassigned Contacts to admin User
				unassigned_contacts.update_all(user_id: c.def_user_id)
			end
		end
  end

  def down
    remove_reference :clients, :def_user
  end
end
