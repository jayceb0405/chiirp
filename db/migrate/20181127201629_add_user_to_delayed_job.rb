class AddUserToDelayedJob < ActiveRecord::Migration[5.2]
  def up
    add_reference :delayed_jobs, :user, index: true
  end

  def down
  	remove_reference :delayed_jobs, :user
  end
end
