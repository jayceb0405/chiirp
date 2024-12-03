class AddUserSuspendAt < ActiveRecord::Migration[5.2]
  def up
  	add_column     :users,             :suspended_at,      :datetime,          null: true,         default: nil
  end

  def down
		remove_column  :users,             :suspended_at
  end
end
