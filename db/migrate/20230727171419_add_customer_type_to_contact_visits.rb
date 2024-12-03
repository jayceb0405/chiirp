class AddCustomerTypeToContactVisits < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "customer_type" to Contacts::Visit table...' do
      add_column :contact_visits, :customer_type, :string
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
