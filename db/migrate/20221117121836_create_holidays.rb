class CreateHolidays < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ClientHolidays table...' do
      create_table :client_holidays do |t|
        t.references :client, foreign_key: true, index: true
        t.string     :name, default: '', null: false
        t.date       :occurs_at
        t.string     :action, default: 'after', null: false

        t.timestamps
      end
    end

    say_with_time 'Updating Users with Holidays permissions...' do

      User.joins(:client).where('clients.data @> ?', { active: true }.to_json).find_each do |user|
        user.permissions.dig('clients_controller') << 'holidays' if user.access_controller?('clients', 'billing') && user.permissions.dig('clients_controller').exclude?('holidays')
        user.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
