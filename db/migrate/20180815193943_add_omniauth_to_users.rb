class AddOmniauthToUsers < ActiveRecord::Migration[5.2]
  def self.up
    add_column :users, :provider, :string
    add_column :users, :uid, :string
  end

  def self.down
    remove_column :users, :provider, :string
    remove_column :users, :uid, :string
  end
end
