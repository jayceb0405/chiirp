class ReduceIndexesOnTwmessages < ActiveRecord::Migration[5.2]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Removing Indexes from Twmessages..." do
			remove_index           :twmessages,        :triggeraction_id
			remove_index           :twmessages,        :status
			remove_index           :twmessages,        :voice_mail_recording_id
			remove_index           :twmessages,        :automated
			remove_index           :twmessages,        :to_phone
			remove_index           :twmessages,        :from_phone
			remove_index           :twmessages,        :message_sid
		end

		say_with_time "Removing Miscellaneous Indexes..." do
			remove_index           :contact_campaigns, :campaign_id
			remove_index           :completed_triggeractions, :triggeraction_id
			add_index              :client_transactions, :setting_key
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end

  def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Adding Indexes to Twmessages..." do
			add_index              :twmessages,        :triggeraction_id
			add_index              :twmessages,        :status
			add_index              :twmessages,        :voice_mail_recording_id
			add_index              :twmessages,        :automated
			add_index              :twmessages,        :to_phone
			add_index              :twmessages,        :from_phone
			add_index              :twmessages,        :message_sid
		end

		say_with_time "Adding Miscellaneous Indexes..." do
			add_index              :contact_campaigns, :campaign_id
			add_index              :completed_triggeractions, :triggeraction_id
			remove_index           :client_transactions, :setting_key
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end
end
