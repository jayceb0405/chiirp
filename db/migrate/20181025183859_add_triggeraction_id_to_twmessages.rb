class AddTriggeractionIdToTwmessages < ActiveRecord::Migration[5.2]
  def up
    add_reference :twmessages, :triggeraction
    remove_column :twmessages, :timestamp
 end

  def down
    remove_reference :twmessages, :triggeraction
    add_column :twmessages, :timestamp, :timestamp
  end
end
