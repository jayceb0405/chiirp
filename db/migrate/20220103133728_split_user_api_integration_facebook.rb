class SplitUserApiIntegrationFacebook < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Splitting Facebook target in UserApiIntegration table...' do

      UserApiIntegration.where(target: 'facebook', name: '').find_each do |user_api_integration|

        if user_api_integration.data.dig('forms').present?
          UserApiIntegration.create(
            user_id:    user_api_integration.user_id,
            target:     'facebook',
            name:       'leads',
            api_key:    user_api_integration.api_key,
            created_at: Time.current,
            updated_at: Time.current,
            data:    {
              forms: user_api_integration.data.dig('forms')
            }
          )
        end

        user_api_integration.data.delete('forms')
        user_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Joining Facebook targets in UserApiIntegration table...' do
      
      UserApiIntegration.where(target: 'facebook', name: 'leads').find_each do |user_api_integration|

        if (facebook_user_api_integration = UserApiIntegration.find_by(user_id: user_api_integration.user_id, target: 'facebook', name: ''))
          facebook_user_api_integration.data['forms'] = user_api_integration.data.dig('forms')
          facebook_user_api_integration.save
          user_api_integration.destroy
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
