class MigrateUserNotifications < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "read_at" column to Review...' do
      add_column :reviews, :read_at, :datetime, null: true, default: nil
      Review.update_all(read_at: Time.current)
    end

    say_with_time 'Migrating notifications in User...' do

      User.all.find_each do |user|
        user.data['notifications'] = { 'review' => {}, 'task' => {}, 'text' => {} }
        user.data['notifications']['review']['matched']       = false
        user.data['notifications']['review']['unmatched']     = false
        user.data['notifications']['review']['by_text']       = false
        user.data['notifications']['review']['by_push']       = false

        user.data['notifications']['task']['by_text']         = user.data.dig('task_notify', 'by_text').nil? ? true : user.data['task_notify']['by_text'].to_bool
        user.data['notifications']['task']['by_push']         = user.data.dig('task_notify', 'by_push').nil? ? true : user.data['task_notify']['by_push'].to_bool
        user.data['notifications']['task']['created']         = user.data.dig('task_notify', 'created').nil? ? true : user.data['task_notify']['created'].to_bool
        user.data['notifications']['task']['updated']         = user.data.dig('task_notify', 'updated').nil? ? true : user.data['task_notify']['updated'].to_bool
        user.data['notifications']['task']['due']             = user.data.dig('task_notify', 'due').nil? ? true : user.data['task_notify']['due'].to_bool
        user.data['notifications']['task']['deadline']        = user.data.dig('task_notify', 'deadline').nil? ? true : user.data['task_notify']['deadline'].to_bool
        user.data['notifications']['task']['completed']       = user.data.dig('task_notify', 'completed').nil? ? true : user.data['task_notify']['completed'].to_bool

        user.data['notifications']['text']['arrive']          = if user.data.dig('text_notify', 'arrive').present?
                                                                   user.data['text_notify']['arrive']
                                                                 else
                                                                   [user.id]
                                                                 end
        user.data['notifications']['text']['on_contact']      = user.data.dig('text_notify', 'on_contact').nil? ? false : user.data['text_notify']['on_contact'].to_bool

        user.permissions['integrations_controller'] ||= []
        user.permissions['integrations_controller']  << 'google_reviews'
        user.permissions['integrations_controller']  << 'google_review_replies'

        user.data.delete('task_notify')
        user.data.delete('text_notify')
        user.save
      end
    end

    say_with_time 'Migrating Google Reviews Actions in ClientApiIntegration...' do

      ClientApiIntegration.where(target: 'google', name: 'reviews').find_each do |client_api_integration|
        new_actions = {}

        (1..5).each do |star|
          new_actions[star] = {
            campaign_id: client_api_integration.data.dig('actions', 'campaign_id').to_i,
            group_id: client_api_integration.data.dig('actions', 'group_id').to_i,
            stage_id: client_api_integration.data.dig('actions', 'stage_id').to_i,
            tag_id: client_api_integration.data.dig('actions', 'tag_id').to_i
          }
        end

        client_api_integration.data['actions'] = new_actions
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing "read_at" column from Review...' do
      remove_column :reviews, :read_at
    end

    say_with_time 'Rolling back notifications in User...' do

      User.all.find_each do |user|
        user.data['task_notify'] = {}
        user.data['task_notify']['by_text']    = user.data.dig('notifications', 'task', 'by_text').nil? ? true : user.data['notifications']['task']['by_text'].to_bool
        user.data['task_notify']['by_push']    = user.data.dig('notifications', 'task', 'by_push').nil? ? true : user.data['notifications']['task']['by_push'].to_bool
        user.data['task_notify']['created']    = user.data.dig('notifications', 'task', 'created').nil? ? true : user.data['notifications']['task']['created'].to_bool
        user.data['task_notify']['updated']    = user.data.dig('notifications', 'task', 'updated').nil? ? true : user.data['notifications']['task']['updated'].to_bool
        user.data['task_notify']['due']        = user.data.dig('notifications', 'task', 'due').nil? ? true : user.data['notifications']['task']['due'].to_bool
        user.data['task_notify']['deadline']   = user.data.dig('notifications', 'task', 'deadline').nil? ? true : user.data['notifications']['task']['deadline'].to_bool
        user.data['task_notify']['completed']  = user.data.dig('notifications', 'task', 'completed').nil? ? true : user.data['notifications']['task']['completed'].to_bool

        user.data['text_notify'] = {}
        user.data['text_notify']['arrive']     = if user.data.dig('notifications', 'text', 'arrive').present?
                                                   user.data['notifications']['text']['arrive']
                                                 else
                                                   [user.id]
                                                 end
        user.data['text_notify']['on_contact'] = user.data.dig('notifications', 'text', 'on_contact').nil? ? false : user.data['notifications']['text']['on_contact'].to_bool

        user.permissions['integrations_controller'] ||= []
        user.permissions['integrations_controller'].delete('google_reviews')
        user.permissions['integrations_controller'].delete('google_review_replies')

        user.data.delete('notifications')
        user.save
      end
    end

    say_with_time 'Rolling back Google Reviews Actions in ClientApiIntegration...' do

      ClientApiIntegration.where(target: 'google', name: 'reviews').find_each do |client_api_integration|
        new_actions = {
          campaign_id: client_api_integration.data.dig('actions', '1', 'campaign_id').to_i,
          group_id: client_api_integration.data.dig('actions', '1', 'group_id').to_i,
          stage_id: client_api_integration.data.dig('actions', '1', 'stage_id').to_i,
          tag_id: client_api_integration.data.dig('actions', '1', 'tag_id').to_i
        }

        client_api_integration.data['actions'] = new_actions
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
