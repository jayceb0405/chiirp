class TwmessageFolders < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Folders table...' do
      create_table :folders do |t|
        t.references :client,            foreign_key: true,                      index: true
        t.string     :name,              default: '',        null: false,        index: true

        t.timestamps
      end
    end

    say_with_time 'Creating TwmessageFolders table...' do
      create_table :twmessage_folders do |t|
        t.references :twmessage,         foreign_key: true,                      index: true
        t.references :folder,            foreign_key: true,                      index: true

        t.timestamps
      end
    end

    say_with_time 'Removing OldData from Triggeractions table...' do
      remove_column :triggeractions, :old_data
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
