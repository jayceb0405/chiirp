class ClientKpis < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ClientKpis table...' do

      create_table :client_kpis do |t|
        t.references    :client, foreign_key: true, index: true
        t.string        :name,                             default: '',             null: false
        t.string        :criteria_01,                      default: '',             null: false
        t.boolean       :c_01_in_period,                   default: true,           null: false
        t.string        :criteria_02,                      default: '',             null: false
        t.boolean       :c_02_in_period,                   default: true,           null: false
        t.string        :operator,                         default: '/',            null: false
        t.string        :color,                            default: '',             null: false

        t.timestamps
      end
    end

    say_with_time 'Adding maximum KPI count to Client table...' do

      Client.find_each do |client|
        client.max_kpis_count = 10
        client.save
      end
    end

    say_with_time 'Adding maximum KPI count to Package table...' do

      Package.find_each do |package|
        package.max_kpis_count = 10
        package.save
      end
    end

    say_with_time 'Adding KPI permission to User table...' do

      User.find_each do |user|
        user.permissions['clients_controller'] << 'kpis'
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Deleting ClientKpis table...' do
      drop_table :client_kpis
    end

    say_with_time 'Removing maximum KPI count from Client table...' do

      Client.find_each do |client|
        client.data.delete('max_kpis_count')
        client.save
      end
    end

    say_with_time 'Removing maximum KPI count from Package table...' do

      Package.find_each do |package|
        package.package_data.delete('max_kpis_count')
        package.save
      end
    end

    say_with_time 'Removing KPI permission from User table...' do

      User.find_each do |user|
        user.permissions['clients_controller'].delete('kpis')
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
