class RemoveIosRegistration < ActiveRecord::Migration[5.2]
  def up
  	remove_column :users, :ios_registration

  	add_column :contacts, :newfirstname, :string, default: "", null: false
  	add_column :contacts, :newlastname, :string, default: "", null: false

  	# update newfirstname & new lastname
  	Contact.where("firstname IS null").update_all(firstname: "")
  	Contact.where("lastname IS null").update_all(lastname: "")
  	Contact.update_all("newfirstname = firstname")
  	Contact.update_all("newlastname = lastname")

  	remove_column :contacts, :firstname
  	remove_column :contacts, :lastname
  	rename_column :contacts, :newfirstname, :firstname
  	rename_column :contacts, :newlastname, :lastname
  	add_index :contacts, :firstname
  	add_index :contacts, :lastname
  end

  def down
  	add_column :users, :ios_registration, :string, default: "", index: true

  	add_column :contacts, :newfirstname, :string
  	add_column :contacts, :newlastname, :string

  	# update newfirstname & new lastname
  	Contact.update_all("newfirstname = firstname")
  	Contact.update_all("newlastname = lastname")

  	remove_column :contacts, :firstname
  	remove_column :contacts, :lastname
  	rename_column :contacts, :newfirstname, :firstname
  	rename_column :contacts, :newlastname, :lastname
  	add_index :contacts, :firstname
  	add_index :contacts, :lastname
  end
end
