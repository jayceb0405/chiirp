class AddLocationToContacts < ActiveRecord::Migration[5.2]
  def up
		add_column     :contacts,          :address1,          :string,            null: false,        default: ""
		add_column     :contacts,          :address2,          :string,            null: false,        default: ""
		add_column     :contacts,          :city,              :string,            null: false,        default: ""
		add_column     :contacts,          :state,             :string,            null: false,        default: ""
		add_column     :contacts,          :zipcode,           :string,            null: false,        default: ""
		add_column     :contacts,          :alt_phone,         :string,            null: false,        default: ""
  end

  def down
		remove_column  :contacts,          :address1
		remove_column  :contacts,          :address2
		remove_column  :contacts,          :city
		remove_column  :contacts,          :state
		remove_column  :contacts,          :zipcode
		remove_column  :contacts,          :alt_phone
  end
end
