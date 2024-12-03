class CreateUsersSignInDebugs < ActiveRecord::Migration[7.2]
  def change
    create_table :sign_in_debugs do |t|
      t.belongs_to :user, null: true, foreign_key: true
      t.boolean :user_signed_in?, default: false, null: false
      t.string :email
      t.text :password
      t.string :commit
      t.string :remote_ip
      t.text :user_agent
      t.jsonb :data, default: {}

      t.timestamps
    end
    add_index :sign_in_debugs, :email
    add_index :sign_in_debugs, [:email, :user_signed_in?]
    add_index :sign_in_debugs, :remote_ip
    add_index :sign_in_debugs, :data, using: :gin
  end
end
