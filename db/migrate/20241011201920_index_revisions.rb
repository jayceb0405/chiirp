class IndexRevisions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding indexes on tables...' do
      add_index :client_api_integrations, [:client_id, :target, :name], algorithm: :concurrently
      add_index :delayed_jobs, [:user_id, :triggeraction_id, :run_at, :process, :failed_at, :locked_at], algorithm: :concurrently
      add_index :delayed_jobs, [:triggeraction_id, :user_id, :run_at, :group_process, :failed_at, :locked_at], algorithm: :concurrently
      add_index :delayed_jobs, [:process, :user_id], algorithm: :concurrently
      add_index :delayed_jobs, [:group_uuid, :user_id, :group_process], algorithm: :concurrently
      add_index :delayed_jobs, [:contact_id, :process], algorithm: :concurrently
      add_index :delayed_jobs, [:contact_campaign_id, :triggeraction_id], algorithm: :concurrently
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
