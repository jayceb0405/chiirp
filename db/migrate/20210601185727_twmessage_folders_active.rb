class TwmessageFoldersActive < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding Active to Folders table...' do
      add_column   :folders,           :active,            :boolean,           null: false,        default: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
