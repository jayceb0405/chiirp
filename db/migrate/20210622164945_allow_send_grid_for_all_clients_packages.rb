class AllowSendGridForAllClientsPackages < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Allowing all Clients access to SendGrid...' do

      Client.find_each do |client|
        client.integrations_allowed << 'sendgrid' unless client.integrations_allowed.include?('sendgrid')
        client.save
      end
    end

    say_with_time 'Allowing all Packages access to SendGrid...' do

      Package.find_each do |package|
        package.integrations_allowed << 'sendgrid' unless package.integrations_allowed.include?('sendgrid')
        package.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
