class UpdateUserStagesAllContactPermission < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding Stages All Contacts permission to User model...' do

      User.find_each do |user|

        if user.permissions.dig('stages_controller').include?('allowed')
          user.permissions['stages_controller'] << 'all_contacts'
          user.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
