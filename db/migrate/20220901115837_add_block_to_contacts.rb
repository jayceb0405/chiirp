class AddBlockToContacts < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Modifying "sleep" in Contacts table...' do
      rename_column :contacts, :sleep, :old_sleep
      add_column :contacts, :sleep, :boolean, null: false, default: false
      Contact.where(old_sleep: 1).update_all(sleep: true)
      remove_column :contacts, :old_sleep
    end

    say_with_time 'Updating "sleep" in UserSettings table...' do
      UserSetting.where(controller_action: 'contacts_search').find_each do |user_setting|
        user_setting.data['sleep'] = user_setting.data.dig('sleep').to_i.zero? ? 'false' : user_setting.data.dig('sleep').to_i == 1 ? 'true' : 'all'
        user_setting.data['block'] = 'all'
        user_setting.save
      end
    end

    say_with_time 'Adding "block" to Contacts table...' do
      add_column :contacts, :block, :boolean, null: false, default: false
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Modifying "sleep" in Contacts table...' do
      rename_column :contacts, :sleep, :old_sleep
      add_column :contacts, :sleep, :string
      Contact.where(old_sleep: true).update_all(sleep: '1')
      remove_column :contacts, :old_sleep
    end

    say_with_time 'Updating "sleep" in UserSettings table...' do
      UserSetting.where(controller_action: 'contacts_search').find_each do |user_setting|
        user_setting.data['sleep'] = user_setting.data.dig('sleep').to_s == 'false' ? '0' : user_setting.data.dig('sleep').to_s == 'true' ? '1' : '2'
        user_setting.data.delete('block')
        user_setting.save
      end
    end

    say_with_time 'Removing "block" from Contacts table...' do
      remove_column :contacts, :block
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
