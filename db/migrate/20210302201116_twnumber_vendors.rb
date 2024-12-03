class TwnumberVendors < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding phone number vendor to Twnumbers table...' do
      add_column   :twnumbers,         :phone_vendor,      :string,          null: false,        default: 'twilio'
    end

    say_with_time 'Adding phone number vendor to Clients table...' do
      add_column   :clients,           :phone_vendor,      :string,          null: false,        default: 'twilio'
    end

    say_with_time 'Adding phone number vendor to Packages table...' do
      add_column   :packages,          :phone_vendor,      :string,          null: false,        default: 'twilio'
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
