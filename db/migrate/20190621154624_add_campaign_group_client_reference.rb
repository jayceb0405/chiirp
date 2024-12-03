class AddCampaignGroupClientReference < ActiveRecord::Migration[5.2]
	def up
		add_reference  :campaign_groups,   :client
	end

	def down
		remove_reference  :campaign_groups,   :client
	end
end
