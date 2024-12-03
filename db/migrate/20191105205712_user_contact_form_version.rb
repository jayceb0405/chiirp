class UserContactFormVersion < ActiveRecord::Migration[5.2]
  def up
    add_column     :user_contact_forms,          :marketplace,       :boolean,           null: false,        default: false
    add_column     :user_contact_forms,          :marketplace_ok,    :boolean,           null: false,        default: false
    add_column     :user_contact_forms,          :marketplace_image, :string
    add_column     :user_contact_forms,          :price,             :integer,           null: false,        default: 0

  	UserContactForm.all.each do |user_contact_form|
  		user_contact_form.update( version: 2 )
  	end
  end

  def down
    remove_column  :user_contact_forms,          :marketplace
    remove_column  :user_contact_forms,          :marketplace_ok
    remove_column  :user_contact_forms,          :marketplace_image
    remove_column  :user_contact_forms,          :price

  	UserContactForm.all.each do |user_contact_form|
  		user_contact_form.formatting.delete("version")
  		user_contact_form.save
  	end
  end
end
