class ChangeUsersFor2Fa < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :otp_required_for_login, :boolean
    remove_column :users, :confirmed_at, :datetime
    remove_column :users, :unconfirmed_email, :string
    remove_column :users, :consumed_timestep, :integer

    add_column :users, :otp_secret_at, :string
  end
end
