class ChangeStagesShowCustomFieldsToJsonB < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing ShowCustomFields in Stages table to JsonB...' do
      remove_column :stages, :show_custom_fields, :string
      add_column :stages, :data, :jsonb, null: false, default: {}
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
