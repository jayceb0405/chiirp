class AddDataToStageParents < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding data JsonB field to StageParents table...' do
      add_column :stage_parents, :data, :jsonb, null: false, default: {}
      StageParent.update_all(data: {"users_permitted": [0]})
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
