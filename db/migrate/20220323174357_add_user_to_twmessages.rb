class AddUserToTwmessages < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding user_id to Twmessages model...' do
      add_reference   :twmessages,     :user,              null: true,         default: nil,       index: true,        foreign_key: true
      add_foreign_key :twmessages,     :triggeractions,    validate: false

      # execute this query after migration in a console
      # ActiveRecord::Base.record_timestamps = false
      # Twmessage.where(triggeraction_id: 0).update_all(triggeraction_id: nil)
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
