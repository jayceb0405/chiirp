class AddTotalsToContactEstimates < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding total columns to ContactEstimates...' do
      add_column :contact_estimates, :total_amount, :decimal, null: false, default: 0
      add_column :contact_estimates, :outstanding_balance, :decimal, null: false, default: 0
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing total columns from ContactEstimates...' do
      remove_column :contact_estimates, :total_amount
      remove_column :contact_estimates, :outstanding_balance
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
