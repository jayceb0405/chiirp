class AddIndexForUnreadMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Client::Notes...' do
      add_index :messages, [:contact_id, :read_at, :automated], algorithm: :concurrently
      add_index :messages, [:read_at, :automated, :contact_id], algorithm: :concurrently
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
