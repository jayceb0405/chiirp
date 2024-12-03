class AddNameToTriggers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding Name to Triggers...' do
      add_column :triggers, :name, :string, default: '', null: false

      # Trigger.find_each do |trigger|
      #   trigger.update(name: trigger.data.dig(:name) || '')
      # end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
