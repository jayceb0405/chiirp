class ConvertActiveContactsPeriod < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Updating active_contacts_period in UserSettings table...' do
      UserSetting.where(controller_action: 'message_central').where('data ILIKE ?', '%active_contacts_period%').each do |user_setting|
        user_setting.data[:active_contacts_period] = user_setting.data.dig(:active_contacts_period).to_i + 1
        user_setting.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
