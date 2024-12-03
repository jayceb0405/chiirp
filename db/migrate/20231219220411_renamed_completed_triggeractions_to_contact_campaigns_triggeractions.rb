class RenamedCompletedTriggeractionsToContactCampaignsTriggeractions < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Renaming CompletedTriggeractions to Contacts::Campaigns::Triggeractions...' do
      rename_table :completed_triggeractions, :contact_campaign_triggeractions
    end

    say_with_time 'Adding "outcome" to Contacts::Campaigns::Triggeractions...' do
      add_column :contact_campaign_triggeractions, :outcome, :string, default: nil, null: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'

    # ActiveRecord::Base.record_timestamps = false
    # puts 'Turned off timestamps.'

    # puts 'Updating "outcome" in Contacts::Campaigns::Triggeractions...'
    # Contacts::Campaigns::Triggeraction.includes(:delayed_jobs).find_each do |contact_campaign_triggeraction|

    #   if contact_campaign_triggeraction.delayed_jobs.find { |dj| dj.triggeraction_id == contact_campaign_triggeraction.triggeraction_id }.present?
    #     contact_campaign_triggeraction.update(outcome: 'scheduled')
    #   else
    #     contact_campaign_triggeraction.update(outcome: 'completed')
    #   end
    # end
    # puts 'Update complete.'

    # ActiveRecord::Base.record_timestamps = true
    # puts 'Turned on timestamps.'
  end
end
