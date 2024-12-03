class AddLogoImageToCampaigns < ActiveRecord::Migration[5.2]
  def up
  	add_reference  :campaigns,         :client_attachment,           index: true
		add_reference  :campaign_groups,   :client_attachment,           index: true
  end

  def down
  	remove_reference  :campaigns,         :client_attachment
		remove_reference  :campaign_groups,   :client_attachment
  end
end
