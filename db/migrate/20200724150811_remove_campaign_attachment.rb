class RemoveCampaignAttachment < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

  	remove_reference  :campaigns,         :client_attachment
		remove_reference  :campaign_groups,   :client_attachment

		remove_column :user_contact_forms, :old_background_image
		remove_column :user_contact_forms, :old_marketplace_image
		remove_column :user_contact_forms, :old_logo_image

    say_with_time "Updating existing SiteChats with defaults..." do
      ClientWidget.find_each do |client_widget|
        client_widget.update(
          show_bubble: false,
          bubble_text: "Hi 👋!  Have a Question?  Text us now."
        )
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

  	add_reference  :campaigns,         :client_attachment,           index: true
		add_reference  :campaign_groups,   :client_attachment,           index: true

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end
end
