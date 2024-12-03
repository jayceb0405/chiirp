class AddFieldsToUserContactForm < ActiveRecord::Migration[5.2]
  def up
  	add_column :user_contact_forms, :form_fields, :text, default: "", null: false
  	add_column :user_contact_forms, :formatting, :text, default: "", null: false

  	UserContactForm.all.each do |ucf|
  		ucf.update( form_fields: ucf.data )
  	end

  	remove_column :user_contact_forms, :data
  end

  def down
  	add_column :user_contact_forms, :data, :text, default: "", null: false

  	UserContactForm.all.each do |ucf|
  		ucf.update( data: ucf.form_fields )
  	end

  	remove_column :user_contact_forms, :form_fields
  	remove_column :user_contact_forms, :formatting
  end
end
