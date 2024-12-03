class RenameSystemSettingsToVersions < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Renaming SystemSettings table to Versions...' do
      rename_table :system_settings, :versions
    end

    say_with_time 'Changing Versions table columns...' do
      remove_column :versions, :end_date
      remove_column :versions, :setting_key
      rename_column :versions, :setting_value, :header
      add_column    :versions, :data, :jsonb, null: false, default: {}
      add_index     :versions, :data, using: :gin
    end

    say_with_time 'Updating Versions data column...' do
      Version.update_all(data: {tenants: ['chiirp', 'dropresponder', 'dsleadpro', 'roofleadpro', 'upflow', 'virtualsolarpro']})
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
