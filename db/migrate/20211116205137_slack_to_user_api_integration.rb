class SlackToUserApiIntegration < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating User Slack data to UserApiIntegration model...' do

      User.where("data -> 'slack_token' != ?", ''.to_json).or(User.where("data -> 'slack_channel' != ?", ''.to_json)).find_each do |user|

        if (user_api_integration = user.user_api_integrations.find_or_initialize_by(target: 'slack', name: ''))
          user_api_integration.data = {
            token: user.data.dig('slack_token').to_s,
            expires_at: 0,
            refresh_token: '',
            notifications_channel: user.data.dig('slack_channel').to_s
          }
          user_api_integration.created_at = Time.current
          user_api_integration.updated_at = Time.current
          user_api_integration.save

          user.data.delete('slack_token')
          user.data.delete('slack_channel')
          user.save
        end
      end
    end

    say_with_time 'Adding new data to OrgUsers...' do
      add_column :org_users, :email, :string, null: false, default: ''
    end

    say_with_time 'Updating User permissions to Integrations...' do
      User.where("permissions -> 'integrations_controller' = ?", ["allowed"].to_json).find_each do |user|
        user.permissions['integrations_controller'] = ['client', 'user']
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Reverting UserApiIntegration Slack data to User model...' do

      UserApiIntegration.where(target: 'slack').find_each do |user_api_integration|

        if (user = user_api_integration.user)
          user.data['slack_token'] = user_api_integration.data.dig('token').to_s
          user.data['slack_channel'] = user_api_integration.data.dig('notifications_channel').to_s
          user.save

          user_api_integration.destroy
        end
      end
    end

    say_with_time 'Removing data from OrgUsers...' do
      remove_column :org_users, :email
    end

    say_with_time 'Updating User permissions to Integrations...' do
      User.where("permissions -> 'integrations_controller' ?| array[:options]", options: 'client').find_each do |user|
        user.permissions['integrations_controller'] = ['allowed']
        user.save
      end
      User.where("permissions -> 'integrations_controller' ?| array[:options]", options: 'user').find_each do |user|
        user.permissions['integrations_controller'] = []
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
