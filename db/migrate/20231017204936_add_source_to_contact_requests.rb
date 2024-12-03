class AddSourceToContactRequests < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "source" to Contacts::Requests table...' do
      add_column :contact_requests, :source, :string
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
