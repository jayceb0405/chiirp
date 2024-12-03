class RemoveUniqueFromTwmessagesIndex < ActiveRecord::Migration[6.0]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Removing Uniqueness from Twmessages created_at index..." do
	    remove_index :twmessages, :created_at
			add_index :twmessages, :created_at
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end

  def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Adding Uniqueness to Twmessages created_at index..." do
	    remove_index :twmessages, :created_at
	    add_index :twmessages, :created_at, unique: true
	  end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end
end
