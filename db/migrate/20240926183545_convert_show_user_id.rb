class ConvertShowUserId < ActiveRecord::Migration[7.2]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating show_user_id to show_user_ids in UserSettings table...' do

      # UserSetting.where(controller_action: ['contacts_search', 'message_central']).each do |user_setting|
      #   if user_setting.data.dig('show_user_id')
      #     user_setting.data['show_user_ids'] = [user_setting.data['show_user_id'] || user_setting.user_id]
      #     user_setting.data.delete('show_user_id')
      #   elsif user_setting.data.dig(:show_user_id)
      #     user_setting.data[:show_user_ids] = [user_setting.data[:show_user_id] || user_setting.user_id]
      #     user_setting.data.delete(:show_user_id)
      #   end

      #   user_setting.save
      # end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
