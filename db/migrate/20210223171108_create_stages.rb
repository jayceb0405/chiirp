class CreateStages < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating StageParents table...' do
      create_table :stage_parents do |t|
        t.references :client,            foreign_key: true,                      index: true
        t.string     :name,              default: '',        null: false,        index: true

        t.timestamps
      end
    end

    say_with_time 'Creating Stages table...' do
      create_table :stages do |t|
        t.references :stage_parent,      foreign_key: true,                      index: true
        t.references :campaign,          default: 0,         null: false
        t.string     :name,              default: '',        null: false,        index: true
        t.integer    :sort_order,        default: 0,         null: false

        t.timestamps
      end
    end

    say_with_time 'Adding Stage id field to Contacts...' do
      add_reference  :contacts, :stage, default: 0, null: false
    end

    say_with_time 'Adding Stage id field to QuickPages...' do
      add_reference  :user_contact_forms, :stage, default: 0, null: false
    end

    say_with_time 'Adding Stage id field to SiteChats...' do
      add_reference  :client_widgets, :stage, default: 0, null: false
    end

    say_with_time 'Adding Stage id field to Tags...' do
      add_reference  :tags, :stage, default: 0, null: false
    end

    say_with_time 'Adding Stage id field to Trackable Links...' do
      add_reference  :trackable_links, :stage, default: 0, null: false
    end

    say_with_time 'Adding Stage id field to Webhooks...' do
      add_reference  :webhooks, :stage, default: 0, null: false
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
