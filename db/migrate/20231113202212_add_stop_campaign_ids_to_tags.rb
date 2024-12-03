class AddStopCampaignIdsToTags < ActiveRecord::Migration[7.1]
  def change
    add_column :tags, :stop_campaign_ids, :bigint, array: true, default: []
  end
end
