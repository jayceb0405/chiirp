class RemoveUnusedIndexes < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing indexes...' do
      remove_index :client_transactions, :created_at
      remove_index :contacts, :lead_source_id
      remove_index :contacts, :ext_ref_id
      remove_index :contact_phones, :label
      remove_index :contact_jobs, :invoice_number
      remove_index :contact_estimates, :estimate_number
      remove_index :messages, :aiagent_session_id
      remove_index :messages, :user_id
      remove_index :contact_api_integrations, :name
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
