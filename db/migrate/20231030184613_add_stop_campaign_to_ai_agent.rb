class AddStopCampaignToAiAgent < ActiveRecord::Migration[7.1]
  def change
    change_table :aiagents do |t|
      t.bigint :stop_campaign_ids, array: true
      t.bigint :help_stop_campaign_ids, array: true
      t.bigint :session_length_stop_campaign_ids, array: true
    end
  end
end
