class ApplyMessageFolderIdsToContacts < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Updating Contacts with selected Folders...' do
      TwmessageFolder.find_each do |twmessage_folder|
        contact = twmessage_folder.twmessage.contact
        contact.folders << twmessage_folder.folder_id
        contact.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
