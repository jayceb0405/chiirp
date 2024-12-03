class AddGoogleCalendarIdToUser < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :google_calendar_id, :string, default: ""
  end

  def down
  	remove_column :users, :google_calendar_id
  end
end
