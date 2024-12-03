class AddStartedAtToCampaigns < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "last_started_at" to Campaigns table...' do
      add_column :campaigns, :last_started_at, :datetime
    end

    # say_with_time 'Updating "last_started_at" for all Campaigns...' do
    #   ContactCampaign.select('campaign_id, MAX(created_at) AS created_at').group(:campaign_id).each do |contact_campaign|
    #     Campaign.find_by(id: contact_campaign.campaign_id)&.update(last_started_at: contact_campaign.created_at)
    #   end
    # end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
