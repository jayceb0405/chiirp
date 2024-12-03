class AddBusinessUnitIdToContactJobs < ActiveRecord::Migration[7.2]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding BusinessUnitId to Contacts::Job table...' do
      add_column :contact_jobs, :business_unit_id, :string, default: nil, null: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
