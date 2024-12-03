class AddStopCampaignIdsToUserContactForms < ActiveRecord::Migration[7.1]
  def change
    add_column :user_contact_forms, :stop_campaign_ids, :bigint, array: true, default: []
  end
end
