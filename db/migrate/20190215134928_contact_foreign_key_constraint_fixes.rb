class ContactForeignKeyConstraintFixes < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :completed_triggeractions, :contact_campaigns
    remove_foreign_key :completed_triggeractions, :triggeractions
    remove_foreign_key :contact_campaigns, :campaigns
    remove_foreign_key :contact_campaigns, :contacts
    remove_foreign_key :push_users, :users
    remove_foreign_key :trackable_links_hits, :trackable_short_links
    remove_foreign_key :trackable_short_links, :trackable_links
    remove_foreign_key :triggeractions, :triggers
    remove_foreign_key :triggers, :campaigns
    remove_foreign_key :twmessage_attachments, :twmessages
    remove_foreign_key :twmessages, :contacts
    remove_foreign_key :user_settings, :users
    remove_foreign_key :webhook_maps, :webhooks

    add_foreign_key :completed_triggeractions, :contact_campaigns, on_delete: :cascade
    add_foreign_key :completed_triggeractions, :triggeractions, on_delete: :cascade
    add_foreign_key :contact_campaigns, :campaigns, on_delete: :cascade
    add_foreign_key :contact_campaigns, :contacts, on_delete: :cascade
    add_foreign_key :push_users, :users, on_delete: :cascade
    add_foreign_key :trackable_links_hits, :trackable_short_links, on_delete: :cascade
    add_foreign_key :trackable_short_links, :trackable_links, on_delete: :cascade
    add_foreign_key :triggeractions, :triggers, on_delete: :cascade
    add_foreign_key :triggers, :campaigns, on_delete: :cascade
    add_foreign_key :twmessage_attachments, :twmessages, on_delete: :cascade
    add_foreign_key :twmessages, :contacts, on_delete: :cascade
    add_foreign_key :user_settings, :users, on_delete: :cascade
    add_foreign_key :webhook_maps, :webhooks, on_delete: :cascade
  end

  def down
    remove_foreign_key :completed_triggeractions, :contact_campaigns
    remove_foreign_key :completed_triggeractions, :triggeractions
    remove_foreign_key :contact_campaigns, :campaigns
    remove_foreign_key :contact_campaigns, :contacts
    remove_foreign_key :push_users, :users
    remove_foreign_key :trackable_links_hits, :trackable_short_links
    remove_foreign_key :trackable_short_links, :trackable_links
    remove_foreign_key :triggeractions, :triggers
    remove_foreign_key :triggers, :campaigns
    remove_foreign_key :twmessage_attachments, :twmessages
    remove_foreign_key :twmessages, :contacts
    remove_foreign_key :user_settings, :users
    remove_foreign_key :webhook_maps, :webhooks

    add_foreign_key :completed_triggeractions, :contact_campaigns
    add_foreign_key :completed_triggeractions, :triggeractions
    add_foreign_key :contact_campaigns, :campaigns
    add_foreign_key :contact_campaigns, :contacts
    add_foreign_key :push_users, :users
    add_foreign_key :trackable_links_hits, :trackable_short_links
    add_foreign_key :trackable_short_links, :trackable_links
    add_foreign_key :triggeractions, :triggers
    add_foreign_key :triggers, :campaigns
    add_foreign_key :twmessage_attachments, :twmessages
    add_foreign_key :twmessages, :contacts
    add_foreign_key :user_settings, :users
    add_foreign_key :webhook_maps, :webhooks
  end
end
