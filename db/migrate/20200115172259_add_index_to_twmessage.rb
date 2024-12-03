class AddIndexToTwmessage < ActiveRecord::Migration[5.2]
  def up
    add_index      :twmessages, :automated
    add_index      :contacts, :sleep
  end

  def down
    remove_index   :twmessages, :automated
    remove_index   :contacts, :sleep
  end
end
