class AdjustForeignKeys < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :clients, :users
    remove_foreign_key :client_transactions, :clients
    add_foreign_key :clients, :users, column: :def_user_id, on_delete: :cascade
    add_foreign_key :client_transactions, :clients, on_delete: :cascade
  end

  def down
    remove_foreign_key :clients, :users
    remove_foreign_key :client_transactions, :clients
    add_foreign_key :clients, :users, column: :def_user_id
    add_foreign_key :client_transactions, :clients
  end
end
