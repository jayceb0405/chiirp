class ConvertUserTextNotifyToArray < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting Users.text_notify[\'arrive\'] to array of User IDs...' do
      User.all.find_each do |u|
        u.update(text_notify: { arrive: u.text_notify.dig('arrive').to_bool ? [u.id] : [] , on_contact: u.text_notify.dig('on_contact').to_bool })
      end
    end

    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Reverting Users.text_notify[\'arrive\'] to boolean...' do
      User.all.find_each do |u|
        u.update(text_notify: { arrive: u.text_notify.dig('arrive').present? , on_contact: u.text_notify.dig('on_contact').to_bool })
      end
    end

    say 'Turned on timestamps.'
  end
end
