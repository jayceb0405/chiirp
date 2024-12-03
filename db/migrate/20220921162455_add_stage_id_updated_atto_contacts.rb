class AddStageIdUpdatedAttoContacts < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "stage_id_updated_at" to Contacts table...' do
      add_column    :contacts, :stage_id_updated_at,  :datetime
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
