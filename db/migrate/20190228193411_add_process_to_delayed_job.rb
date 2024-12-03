class AddProcessToDelayedJob < ActiveRecord::Migration[5.2]
  def up
    add_column :delayed_jobs, :process, :string, default: ""
    add_index :delayed_jobs, :process
  end

  def down
  	remove_index :delayed_jobs, :process
  	remove_column :delayed_jobs, :process
  end
end
