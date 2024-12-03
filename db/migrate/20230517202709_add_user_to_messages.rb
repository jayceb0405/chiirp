class AddUserToMessages < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "read_by_user_id" to Messages::Message table...' do
      add_reference :messages, :read_at_user, references: :users, foreign_key: { to_table: :users }, index: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
