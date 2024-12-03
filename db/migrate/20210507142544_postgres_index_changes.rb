class PostgresIndexChanges < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing Indexes...' do
      remove_index :completed_triggeractions, :triggeraction_id
      remove_index :contacts, :firstname
      remove_index :contacts, :lastname
      remove_index :contacttags, :tag_id
      remove_index :delayed_jobs, :contact_campaign_id
      remove_index :delayed_jobs, :process
      remove_index :delayed_jobs, :user_id
      remove_index :twmessages, :voice_recording_id
    end

    say_with_time 'Adding Indexes...' do
      add_index    :client_transactions, :created_at
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
