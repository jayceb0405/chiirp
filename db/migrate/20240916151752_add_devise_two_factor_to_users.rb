class AddDeviseTwoFactorToUsers < ActiveRecord::Migration[7.2]
  def change
    # otp
    add_column :users, :otp_secret, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_required_for_login, :boolean

    add_column :users, :unconfirmed_email, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :confirmation_token, :string

    # lockable
    add_column :users, :locked_at, :datetime
    add_column :users, :failed_attempts, :integer
    add_column :users, :unlock_token, :string

    add_index :users, :unlock_token,         unique: true
  end
end
