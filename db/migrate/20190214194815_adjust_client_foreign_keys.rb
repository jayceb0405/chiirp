class AdjustClientForeignKeys < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :campaigns, :clients
    remove_foreign_key :client_attachments, :clients
    remove_foreign_key :contacts, :clients
    remove_foreign_key :trackable_links, :clients
    remove_foreign_key :users, :clients
    remove_foreign_key :voice_mail_recordings, :clients
    remove_foreign_key :webhooks, :clients

    add_foreign_key :campaigns, :clients, on_delete: :cascade
    add_foreign_key :client_attachments, :clients, on_delete: :cascade
    add_foreign_key :contacts, :clients, on_delete: :cascade
    add_foreign_key :trackable_links, :clients, on_delete: :cascade
    add_foreign_key :users, :clients, on_delete: :cascade
    add_foreign_key :voice_mail_recordings, :clients, on_delete: :cascade
    add_foreign_key :webhooks, :clients, on_delete: :cascade
  end

  def down
    remove_foreign_key :campaigns, :clients
    remove_foreign_key :client_attachments, :clients
    remove_foreign_key :contacts, :clients
    remove_foreign_key :trackable_links, :clients
    remove_foreign_key :users, :clients
    remove_foreign_key :voice_mail_recordings, :clients
    remove_foreign_key :webhooks, :clients

    add_foreign_key :campaigns, :clients
    add_foreign_key :client_attachments, :clients
    add_foreign_key :contacts, :clients
    add_foreign_key :trackable_links, :clients
    add_foreign_key :users, :clients
    add_foreign_key :voice_mail_recordings, :clients
    add_foreign_key :webhooks, :clients
  end
end
