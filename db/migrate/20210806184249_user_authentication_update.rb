class UserAuthenticationUpdate < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting UserApiIntegration model target: facebook_leads to facebook...' do
      UserApiIntegration.where(target: 'facebook_leads').update_all(target: 'facebook')
    end

    say_with_time 'Adding Permissions to Users model...' do
      add_column :users, :permissions, :jsonb, null: false, default: {}
    end

    say_with_time 'Assigning Permissions to Users...' do
      User.find_each do |user|
        user.permissions = {
          "users_controller": [
            "allowed",
            "profile",
            "tasks",
            "phone_processing",
            "notifications"
          ],
          "stages_controller": [],
          "central_controller": [],
          "clients_controller": [],
          "surveys_controller": [],
          "widgets_controller": [],
          "campaigns_controller": [],
          "companies_controller": [],
          "dashboard_controller": [
            "allowed",
            "calendar",
            "tasks"
          ],
          "trainings_controller": [],
          "my_contacts_controller": [],
          "integrations_controller": [],
          "import_contacts_controller": [],
          "trackable_links_controller": [],
          "message_broadcast_controller": [],
          "user_contact_forms_controller": [],
          "integrations_servicetitan_controller": []
        }
        user.permissions['users_controller']                     << 'admin_settings' if user.access_level >= 5
        user.permissions['users_controller']                     << 'permissions' if user.access_level >= 5
        user.permissions['stages_controller']                    << 'allowed' if user.client.stages_count.positive?
        user.permissions['central_controller']                   << 'allowed' if user.client.message_central_allowed
        user.permissions['central_controller']                   << 'all_contacts' if user.client.message_central_allowed && user.access_level >= 5
        user.permissions['clients_controller']                    = ["allowed", "profile", "billing", "phone_numbers", "voice_recordings", "tags", "users", "org_chart", "terms"] if user.access_level >= 5
        user.permissions['clients_controller']                   << 'settings' if user.access_level == 10
        user.permissions['clients_controller']                   << 'features' if user.access_level == 10
        user.permissions['clients_controller']                   << 'groups' if user.client.groups_count.positive? && user.access_level >= 5
        user.permissions['clients_controller']                   << 'custom_fields' if user.client.custom_fields_count.positive? && user.access_level >= 5
        user.permissions['clients_controller']                   << 'stages' if user.client.stages_count.positive? && user.access_level >= 5
        user.permissions['clients_controller']                   << 'task_actions' if user.client.tasks_allowed && user.access_level >= 5
        user.permissions['clients_controller']                   << 'message_folders' if user.client.folders_count.positive? && user.access_level >= 5
        user.permissions['surveys_controller']                   << 'allowed' if user.client.surveys_count.positive?
        user.permissions['widgets_controller']                   << 'allowed' if user.client.widgets_count.positive? && user.access_level >= 5
        user.permissions['campaigns_controller']                 << 'allowed' if user.client.campaigns_count.positive? && user.access_level >= 5
        user.permissions['companies_controller']                 << 'allowed' if user.access_level >= 8 && user.client.agency_access
        user.permissions['trainings_controller']                 << 'allowed' if user.client.training.present?
        user.permissions['my_contacts_controller']               << 'allowed' if user.client.my_contacts_allowed
        user.permissions['my_contacts_controller']               << 'all_contacts' if user.client.my_contacts_allowed && user.access_level >= 5
        user.permissions['integrations_controller']              << 'allowed' if user.client.integrations_allowed.present?
        user.permissions['import_contacts_controller']           << 'allowed' if user.client.import_contacts_count.positive?
        user.permissions['trackable_links_controller']           << 'allowed' if user.client.trackable_links_count.positive?
        user.permissions['message_broadcast_controller']         << 'allowed' if user.client.message_broadcast_allowed
        user.permissions['message_broadcast_controller']         << 'all_contacts' if user.client.message_broadcast_allowed && user.access_level >= 5
        user.permissions['user_contact_forms_controller']        << 'allowed' if user.client.quick_leads_count.positive?
        user.permissions['integrations_servicetitan_controller'] << 'contact_balances' if user.client.integrations_allowed.include?('servicetitan')

        user.data['agent']       = (user.access_level == 8)
        user.data['super_admin'] = (user.access_level == 10)

        user.save
      end
    end

    say_with_time 'Converting facebook_leads integration id in Client model to facebook...' do
      Client.where("data->'integrations_allowed' ?| array[:integrations]", integrations: ['facebook_leads']).find_each do |client|
        client.integrations_allowed.delete('facebook_leads')
        client.integrations_allowed << 'facebook'
        client.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting facebook integration id in Client model to facebook_leads...' do
      Client.where("data->'integrations_allowed' ?| array[:integrations]", integrations: ['facebook']).find_each do |client|
        client.integrations_allowed.delete('facebook')
        client.integrations_allowed << 'facebook_leads'
        client.save
      end
    end

    say_with_time 'Converting UserApiIntegration model target: facebook to facebook_leads...' do
      UserApiIntegration.where(target: 'facebook').update_all(target: 'facebook_leads')
    end

    say_with_time 'Removing Permissions from Users model...' do
      remove_column :users, :permissions

      User.find_each do |user|
        user.data.delete('agent')
        user.data.delete('super_admin')
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
