class AddProposalUrlToContactsEstimate < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding proposal_url column to ContactEstimates...' do
      add_column :contact_estimates, :proposal_url, :string, null: false, default: ''
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing proposal_url column from ContactEstimates...' do
      remove_column :contact_estimates, :proposal_url
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
