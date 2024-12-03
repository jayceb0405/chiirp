class UpdateDoorkeeperTables < ActiveRecord::Migration[5.2]
  def change
  	change_column :oauth_access_grants, :scopes,           :string,            null: false,        default: ""
  end
end
