class ChangeTwmessage < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing Messages::Attachments table...' do
      rename_column 'twmessage_attachments', :twmessage_id, :message_id
      rename_table :twmessage_attachments, :message_attachments
    end

    say_with_time 'Changing Messages::Emails table...' do
      rename_column 'twmessage_emails', :twmessage_id, :message_id
      rename_table :twmessage_emails, :message_emails
    end

    say_with_time 'Changing Messages::FolderAssignments table...' do
      rename_column 'twmessage_folders', :twmessage_id, :message_id
      rename_table :twmessage_folders, :message_folder_assignments
    end

    say_with_time 'Changing Messages::Messages table...' do
      rename_table :twmessages, :messages
    end

    say_with_time 'Updating User permissions to Folder Assignments...' do
      User.where("permissions -> 'clients_controller' ?| array[:options]", options: 'message_folders').find_each do |user|
        user.permissions['clients_controller'] << 'folder_assignments'
        user.permissions['clients_controller'].delete('message_folders')
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
