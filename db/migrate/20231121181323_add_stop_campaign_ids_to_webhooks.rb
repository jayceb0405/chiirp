class AddStopCampaignIdsToWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_column :webhooks, :stop_campaign_ids, :bigint, array: true, default: []
  end
end
