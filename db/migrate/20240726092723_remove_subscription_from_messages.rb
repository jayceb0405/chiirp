class RemoveSubscriptionFromMessages < ActiveRecord::Migration[7.1]
  def change
    remove_column :messages, :subscription
    drop_table :contact_subscriptions
  end
end
