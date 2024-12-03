class IndexForeignKeysInCompletedTriggeractions < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :contact_lineitems, name: :index_contact_lineitems_on_lineitemable, column: [:lineitemable_type, :lineitemable_id]
    remove_index :messages, name: :index_messages_on_contact_id, column: :contact_id
    remove_index :messages, name: :index_messages_on_read_at, column: :read_at
    remove_index :messages, name: :index_messages_on_read_at_and_automated, column: [:read_at, :automated]
    remove_index :aiagent_sessions, name: :index_aiagent_sessions_on_contact_id, column: :contact_id
    remove_index :delayed_jobs, name: :delayed_jobs_priority, column: [:priority, :run_at]

    add_index :completed_triggeractions, ["triggeraction_id"], algorithm: :concurrently
    add_index :user_contact_forms, ["campaign_id"], algorithm: :concurrently
    add_index :user_contact_forms, ["tag_id"], algorithm: :concurrently
    add_index :aiagents, ["session_length_campaign_id"], algorithm: :concurrently
    add_index :aiagents, ["session_length_group_id"], algorithm: :concurrently
    add_index :aiagents, ["session_length_tag_id"], algorithm: :concurrently
    add_index :aiagents, ["session_length_stage_id"], algorithm: :concurrently
    add_index :messages, ["triggeraction_id"], algorithm: :concurrently
    add_index :messages, ["voice_mail_recording_id"], algorithm: :concurrently
    add_index :messages, ["user_id"], algorithm: :concurrently
    add_index :messages, ["voice_recording_id"], algorithm: :concurrently
    add_index :messages, ["aiagent_session_id"], algorithm: :concurrently
    add_index :twnumbers, ["vm_greeting_recording_id"], algorithm: :concurrently
    add_index :twnumbers, ["announcement_recording_id"], algorithm: :concurrently
    add_index :contact_fb_pages, ["page_id"], algorithm: :concurrently
    add_index :fcp_invoices, ["job_id"], algorithm: :concurrently
    add_index :delayed_jobs, ["user_id"], algorithm: :concurrently
    add_index :contact_campaigns, ["campaign_id"], algorithm: :concurrently
    add_index :client_widgets, ["campaign_id"], algorithm: :concurrently
    add_index :client_widgets, ["tag_id"], algorithm: :concurrently
  end
end
