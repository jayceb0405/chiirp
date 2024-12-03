class EstimatesBelongToJobs < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting Contacts::Estimate table...' do
      add_reference :contact_estimates, :job, foreign_key: { to_table: :contact_jobs }, index: true

      # Contacts::Job.where.not(estimate_id: nil).find_each do |contact_job|

      #   if (contact_estimate = Contacts::Estimate.find_by(id: contact_job.estimate_id))
      #     contact_estimate.update(job_id: contact_job.id)
      #   end
      # end
    end

    say_with_time 'Converting Contacts::Job table...' do
      remove_column :contact_jobs, :estimate_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting Contacts::Job table...' do
      add_reference :contact_jobs, :estimate, foreign_key: { to_table: :contact_estimates }, index: true

      Contacts::Estimate.where.not(job_id: nil).find_each do |contact_estimate|

        if (contact_job = Contacts::Job.find_by(id: contact_estimate.job_id))
          contact_job.update(estimate_id: contact_estimate.id)
        end
      end
    end

    say_with_time 'Converting Contacts::Estimate table...' do
      remove_column :contact_estimates, :job_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
