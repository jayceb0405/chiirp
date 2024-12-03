class ClientNotes < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Client::Notes...' do
      create_table :client_notes do |t|
        t.references :client, foreign_key: true, index: true
        t.references :user, foreign_key: true, index: true
        t.text       :note

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
