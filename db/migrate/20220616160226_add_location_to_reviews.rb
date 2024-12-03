class AddLocationToReviews < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding location to Reviews table...' do
      add_column :reviews, :account, :string, null: false, default: ''
      add_column :reviews, :location, :string, null: false, default: ''
      add_index  :reviews, :account
      add_index  :reviews, :location
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding location to Reviews table...' do
      remove_column :reviews, :account
      remove_column :reviews, :location
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
