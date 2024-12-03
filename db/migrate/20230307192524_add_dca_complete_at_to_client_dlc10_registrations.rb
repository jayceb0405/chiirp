class AddDcaCompleteAtToClientDlc10Registrations < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding dca_completed_at to Clients::Dlc10::Registrations...' do
      add_column :client_dlc10_registrations, :dca_completed_at, :datetime
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
