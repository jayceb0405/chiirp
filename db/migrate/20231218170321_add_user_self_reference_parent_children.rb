class AddUserSelfReferenceParentChildren < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :parent, null: true, default: nil, index: true, foreign_key: { to_table: :contacts }
  end
end
