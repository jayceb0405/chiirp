class AddDefUserToTwnumberusers < ActiveRecord::Migration[5.2]
  def up
  	add_column     :twnumberusers,     :def_user,          :boolean,           null: false,        default: false
  end

  def down
		remove_column  :twnumberusers,     :def_user
  end
end
