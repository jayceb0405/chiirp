class AddTypeToContactJob < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding job_type to Contacts::Job model...' do
      add_column :contact_jobs, :job_type, :string, null: false, default: ''

      Contacts::Job.where(ext_source: 'servicemonster').find_each do |job|
        job.update(job_type: job.status.downcase)
        job.update(status: 'unscheduled')
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing job_type from Contacts::Job model...' do

      Contacts::Job.where(ext_source: 'servicemonster').find_each do |job|
        job.update(status: job.job_type)
      end

      remove_column :contact_jobs, :job_type, :string, null: false, default: ''
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
