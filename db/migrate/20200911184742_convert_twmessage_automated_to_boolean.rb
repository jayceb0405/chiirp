class ConvertTwmessageAutomatedToBoolean < ActiveRecord::Migration[6.0]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Converting Twmessage (automated) to Boolean..." do
			rename_column :twmessages, :automated, :old_automated
			add_column :twmessages, :automated, :boolean, null: false, default: false

			Twmessage.reset_column_information

			Twmessage.where( old_automated: 1 ).update_all( automated: true )
			Twmessage.where( msg_type: ["voicein", "voiceout"] ).update_all( automated: true )

			remove_column :twmessages, :old_automated
		end

		say_with_time "Converting UserChat (automated) to Boolean..." do
			rename_column :user_chats, :automated, :old_automated
			add_column :user_chats, :automated, :boolean, null: false, default: false

			UserChat.reset_column_information

			UserChat.where( old_automated: 1 ).update_all( automated: true )

			remove_column :user_chats, :old_automated
		end

		say_with_time "Removing old_data from UserApiIntegration..." do
			remove_column :user_api_integrations, :old_data
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end

  def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Reverting Twmessage (automated) to Integer..." do
			rename_column :twmessages, :automated, :old_automated
			add_column :twmessages, :automated, :integer, default: 0, null: false

			Twmessage.reset_column_information

			Twmessage.where( old_automated: true ).update_all( automated: 1 )
			Twmessage.where( msg_type: ["voicein", "voiceout"] ).update_all( automated: 0 )

			remove_column :twmessages, :old_automated
		end

		say_with_time "Reverting UserChat (automated) to Integer..." do
			rename_column :user_chats, :automated, :old_automated
			add_column :user_chats, :automated, :integer, default: 0, null: false

			UserChat.reset_column_information

			UserChat.where( old_automated: true ).update_all( automated: 1 )

			remove_column :user_chats, :old_automated
		end

		say_with_time "Adding old_data to UserApiIntegration..." do
			add_column :user_api_integrations, :old_data, :text, null: false, default: {}.to_yaml
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end
end
