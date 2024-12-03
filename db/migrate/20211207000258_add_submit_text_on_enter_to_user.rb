class AddSubmitTextOnEnterToUser < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding submit_text_on_enter to User model...' do

      User.find_each do |user|
        user.update(submit_text_on_enter: false)
      end

    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
