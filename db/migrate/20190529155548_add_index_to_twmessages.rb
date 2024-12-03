class AddIndexToTwmessages < ActiveRecord::Migration[5.2]
  def up
  	add_timestamps(:client_custom_fields, null: false, default: Time.now)
  	add_timestamps(:client_widgets, null: false, default: Time.now)
  	add_timestamps(:contact_custom_fields, null: false, default: Time.now)
  	add_timestamps(:user_contact_forms, null: false, default: Time.now)
  	add_index :twmessages, :status
  end

  def down
  	remove_index :twmessages, :status
  	remove_timestamps(:client_custom_fields)
  	remove_timestamps(:client_widgets)
  	remove_timestamps(:contact_custom_fields)
  	remove_timestamps(:user_contact_forms)
  end
end
