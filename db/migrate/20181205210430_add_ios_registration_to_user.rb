class AddIosRegistrationToUser < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :ios_registration, :string, default: "", index: true
  end

  def down
  	remove_column :users, :ios_registration
  end
end
