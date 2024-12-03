class AddZapierToUsers < ActiveRecord::Migration[5.2]
  def up
  	add_column :users, :zapier_subscriptions, :text, null: false, default: ""
  	User.all.update(zapier_subscriptions: {})
  end

  def down
  	remove_column :users, :zapier_subscriptions
  end
end
