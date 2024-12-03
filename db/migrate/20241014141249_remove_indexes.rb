class RemoveIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing indexes on tables...' do
      remove_index :client_api_integrations, :client_id
      remove_index :client_api_integrations, :target
      remove_index :client_api_integrations, :name
      remove_index :delayed_jobs, :contact_campaign_id
      remove_index :delayed_jobs, :contact_id
      remove_index :delayed_jobs, :group_uuid
      remove_index :delayed_jobs, :process
      remove_index :delayed_jobs, :triggeraction_id
      remove_index :delayed_jobs, :user_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
