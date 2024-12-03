class AddGroupActionToDelayedJob < ActiveRecord::Migration[5.2]
  def up
    add_column :delayed_jobs, :group_action, :string, default: ""
  end

  def down
  	remove_column :delayed_jobs, :group_action
  end
end
