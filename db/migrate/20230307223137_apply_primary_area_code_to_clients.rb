class ApplyPrimaryAreaCodeToClients < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding primary_area_code to Clients...' do

      Client.find_each do |client|
        client.update(primary_area_code: client.phone.to_s[0,3].presence || '801')
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
