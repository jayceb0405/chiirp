class RemovePasswordFromSignInDebug < ActiveRecord::Migration[7.2]
  def change
    remove_column :sign_in_debugs, :password, :text
  end
end
