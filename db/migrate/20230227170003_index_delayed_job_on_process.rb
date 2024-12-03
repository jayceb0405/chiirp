class IndexDelayedJobOnProcess < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Indexing DelayedJob table on process...' do
      add_index :delayed_jobs, :process
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
