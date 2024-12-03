class ClientWidgetForeignKeyCascade < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :client_custom_fields, :clients
    remove_foreign_key :client_widgets, :clients
    remove_foreign_key :user_contact_forms, :users
    remove_foreign_key :contact_custom_fields, :client_custom_fields
    remove_foreign_key :contact_custom_fields, :contacts

    add_foreign_key :client_custom_fields, :clients, on_delete: :cascade
    add_foreign_key :client_widgets, :clients, on_delete: :cascade
    add_foreign_key :user_contact_forms, :users, on_delete: :cascade
    add_foreign_key :contact_custom_fields, :client_custom_fields, on_delete: :cascade
    add_foreign_key :contact_custom_fields, :contacts, on_delete: :cascade
  end

  def down
    remove_foreign_key :client_custom_fields, :clients
    remove_foreign_key :client_widgets, :clients
    remove_foreign_key :user_contact_forms, :users
    remove_foreign_key :contact_custom_fields, :client_custom_fields
    remove_foreign_key :contact_custom_fields, :contacts

    add_foreign_key :client_custom_fields, :clients
    add_foreign_key :client_widgets, :clients
    add_foreign_key :user_contact_forms, :users
    add_foreign_key :contact_custom_fields, :client_custom_fields
    add_foreign_key :contact_custom_fields, :contacts
  end
end
