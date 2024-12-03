class UpdateMembershipExpirationDays < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Update ClientApiIntegration data...' do

      ClientApiIntegration.where(target: 'servicetitan', name: '').find_each do |client_api_integration|

        client_api_integration.events.select { |_id, e| e['action_type'] == 'membership_expiration' }.each do |_id, event|
          event['membership_days_prior'] = event['membership_expiration_days']
          event.delete('membership_expiration_days')
        end

        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
