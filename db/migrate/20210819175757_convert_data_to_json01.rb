class ConvertDataToJson01 < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Renaming data in ClientTransaction to old_data...' do
      rename_column :client_transactions, :data, :old_data
    end

    say_with_time 'Adding new data to ClientTransaction...' do
      add_column :client_transactions, :data, :jsonb, null: false, default: {}
      add_index  :client_transactions, :data, using: :gin
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
