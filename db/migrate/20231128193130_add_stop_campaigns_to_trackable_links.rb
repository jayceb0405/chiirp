class AddStopCampaignsToTrackableLinks < ActiveRecord::Migration[7.1]
  def change
    add_column :trackable_links, :stop_campaign_ids, :bigint, array: true, default: []
  end
end
