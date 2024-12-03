class OutreachUserToClient < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating Outreach targets in UserApiIntegration model to ClientApiIntegration model...' do

      UserApiIntegration.where(target: 'outreach').find_each do |user_api_integration|
        ClientApiIntegration.create(
          client_id:  user_api_integration.user.client_id,
          target:     user_api_integration.target,
          name:       user_api_integration.name,
          api_key:    user_api_integration.api_key,
          created_at: user_api_integration.created_at,
          updated_at: user_api_integration.updated_at,
          data:       user_api_integration.data
        )
        user_api_integration.destroy
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating Outreach targets in ClientApiIntegration model to UserApiIntegration model...' do

      ClientApiIntegration.where(target: 'outreach').find_each do |client_api_integration|
        UserApiIntegration.create(
          user_id:    client_api_integration.client.users.order(:id).first.id,
          target:     client_api_integration.target,
          name:       client_api_integration.name,
          api_key:    client_api_integration.api_key,
          created_at: client_api_integration.created_at,
          updated_at: client_api_integration.updated_at,
          data:       client_api_integration.data
        )
        client_api_integration.destroy
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
