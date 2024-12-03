class RemoveGoogleCalendarId < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating UserApiIntegration model for Google Integrations...' do

      UserApiIntegration.where(target: 'google', name: 'calendar').find_each do |user_api_integration|
        user_api_integration.data.delete('google_calendar_id')
        user_api_integration.name = ''
        user_api_integration.save
      end
    end

    say_with_time 'Migrating Client model for Google Integrations...' do

      Client.all.find_each do |client|

        if client.data.dig('integrations_allowed').include?('google_calendar')
          client.data['integrations_allowed'].delete('google_calendar')
          client.data['integrations_allowed'] << 'google'
          client.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
