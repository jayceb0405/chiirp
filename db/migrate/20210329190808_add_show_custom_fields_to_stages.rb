class AddShowCustomFieldsToStages < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding ShowCustomFields to Stages table...' do
      add_column   :stages,            :show_custom_fields, :boolean,        null: false,        default: false
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
