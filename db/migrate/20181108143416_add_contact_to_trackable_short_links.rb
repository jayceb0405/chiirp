class AddContactToTrackableShortLinks < ActiveRecord::Migration[5.2]
  def up
  	add_reference :trackable_short_links, :contact
  end

  def down
    remove_reference :trackable_short_links, :contact
  end
end
