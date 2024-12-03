class AddCampaignToWebhooks < ActiveRecord::Migration[5.2]
	def up
		add_reference :webhooks, :campaign, index: true, default: 0
	end

	def down
		remove_reference :webhooks, :campaign, index: true
	end
end
