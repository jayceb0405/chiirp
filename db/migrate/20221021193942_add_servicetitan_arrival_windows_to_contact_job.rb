class AddServicetitanArrivalWindowsToContactJob < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Modifying Contacts::Job table...' do
      add_column :contact_jobs, :scheduled_arrival_window_start_at, :datetime
      add_column :contact_jobs, :scheduled_arrival_window_end_at, :datetime
    end

    say_with_time 'Modifying Contacts::Estimate table...' do
      add_column :contact_estimates, :scheduled_arrival_window_start_at, :datetime
      add_column :contact_estimates, :scheduled_arrival_window_end_at, :datetime
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
