class RemoveSubscriptionTriggeractions < ActiveRecord::Migration[7.1]
  def change
    Triggeraction.where(action_type: [550, 551]).destroy_all
  end
end
