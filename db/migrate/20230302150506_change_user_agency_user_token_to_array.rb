class ChangeUserAgencyUserTokenToArray < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing agency_user_token in User to array...' do

      User.find_each do |user|
        user.data['agency_user_tokens'] = []
        user.data['my_agent_token']     = ''
        user.data.delete('agency_user_token')
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing agency_user_token in User to string...' do

      User.find_each do |user|
        user.data['agency_user_token'] = ''
        user.data.delete('agency_user_tokens')
        user.data.delete('my_agent_token')
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
