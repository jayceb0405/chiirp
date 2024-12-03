class RemoveDashboardField < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing "dashboard" from Campaigns model...' do
      remove_column :campaigns, :dashboard
    end

    say_with_time 'Removing "dashboard" from Groups model...' do
      remove_column :groups, :dashboard
    end

    say_with_time 'Removing "dashboard" from Tags model...' do
      remove_column :tags, :dashboard
    end

    say_with_time 'Removing "dashboard" from TrackableLinks model...' do
      remove_column :trackable_links, :dashboard
    end

    say_with_time 'Removing "dashboard" from VoiceMailRecordings model...' do
      remove_column :voice_mail_recordings, :dashboard
    end

    say_with_time 'Assigning Permissions to Users...' do
      User.find_each do |user|

        if user.admin?
          user.permissions['dashboard_controller'] << 'all_contacts'
          user.permissions['dashboard_controller'] << 'company_tiles'
          user.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "dashboard" to Campaigns model...' do
      add_column :campaigns, :dashboard, :integer, default: 0, null: false
      Campaign.update_all(dashboard: 1)
    end

    say_with_time 'Adding "dashboard" to Groups model...' do
      add_column :groups, :dashboard, :integer, default: 0, null: false
      Group.update_all(dashboard: 1)
    end

    say_with_time 'Adding "dashboard" to Tags model...' do
      add_column :tags, :dashboard, :integer, default: 0, null: false
      Tag.update_all(dashboard: 1)
    end

    say_with_time 'Adding "dashboard" to TrackableLinks model...' do
      add_column :trackable_links, :dashboard, :integer, default: 0, null: false
      TrackableLink.update_all(dashboard: 1)
    end

    say_with_time 'Adding "dashboard" to VoiceMailRecordings model...' do
      add_column :voice_mail_recordings, :dashboard, :integer, default: 0, null: false
      VoiceMailRecording.update_all(dashboard: 1)
    end

    say_with_time 'Removing Permissions from Users...' do
      User.find_each do |user|

        if user.permissions['dashboard_controller'].include?('all_contacts') || user.permissions['dashboard_controller'].include?('company_tiles')
          user.permissions['dashboard_controller'].delete('all_contacts')
          user.permissions['dashboard_controller'].delete('company_tiles')
          user.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
