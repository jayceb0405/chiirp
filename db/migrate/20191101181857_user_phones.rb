class UserPhones < ActiveRecord::Migration[5.2]
  def up
  	User.all.each do |user|
  		user.firstname = "" if user.firstname.nil?
  		user.lastname  = "" if user.lastname.nil?
  		user.phone     = "" if user.phone.nil?
  		user.email     = "" if user.email.nil?
  		user.save
  	end

  	change_column  :users,             :firstname,         :string,            null: false,        default: ""
  	change_column  :users,             :lastname,          :string,            null: false,        default: ""
  	change_column  :users,             :phone,             :string,            null: false,        default: ""
  	change_column  :users,             :email,             :string,            null: false,        default: ""
    change_column  :contacts,          :phone,             :string,            null: false,        default: ""
    change_column  :twmessages,        :from_phone,        :string,            null: false,        default: ""
    change_column  :twmessages,        :to_phone,          :string,            null: false,        default: ""
    change_column  :twnumbers,         :phonenumber,       :string,            null: false,        default: ""
    change_column  :campaigns,         :default_phone,     :string,            null: false,        default: ""

    add_index      :users,             :phone

  	User.all.each do |user|
  		user.update( phone_in: user.phone, phone_out: user.phone )
  	end
  end

  def down
    remove_index   :users,             :phone
  end
end
