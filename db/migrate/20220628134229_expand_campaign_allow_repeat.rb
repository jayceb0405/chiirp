class ExpandCampaignAllowRepeat < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Expanding allow_repeat in Campaign table...' do
      Campaign.all.find_each do |campaign|
        campaign.update(allow_repeat_interval: 0, allow_repeat_period: 'immediately')
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Expanding allow_repeat in Campaign table...' do
      Campaign.all.find_each do |campaign|
        campaign.data.delete('allow_repeat_interval')
        campaign.data.delete('allow_repeat_period')
        campaign.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
