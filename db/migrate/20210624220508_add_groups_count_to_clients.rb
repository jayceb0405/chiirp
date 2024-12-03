class AddGroupsCountToClients < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Allowing all Clients maximum of 30 Groups...' do

      Client.find_each do |client|
        client.update(groups_count: 30)
      end

      Package.find_each do |package|
        package.update(groups_count: 30)
      end
    end

    say_with_time 'Allowing select Clients higher Group maximums...' do

      Client.where(id: [1, 339, 945, 1617, 126, 1485, 182, 401, 428, 439, 1352, 771, 1515, 304, 1180, 301, 1028, 5, 473, 483, 455, 773]).find_each do |client|
        client.update(groups_count: client.groups.count + 10)
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
