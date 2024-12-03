class RemoveUnusedIndexes02 < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing indexes...' do
      remove_index :message_attachments, :contact_attachment_id
      remove_index :messages, :voice_mail_recording_id
      remove_index :messages, :voice_recording_id
      remove_index :messages, :msg_type
      remove_index :messages, :triggeraction_id
      remove_index :contacts, :parent_id
      remove_index :contacts, :group_id
      remove_index :contact_api_integrations, :target
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
