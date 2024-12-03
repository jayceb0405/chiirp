class CreateCampaigns < ActiveRecord::Migration[5.2]
  def up
    create_table :campaigns do |t|
      t.references :client, index: true
      t.string     :name
      t.boolean    :active, default: true
      t.boolean    :allow_repeat, default: true
      t.timestamps
    end

    create_table :campaignusers do |t|
      t.references :user, index: true
      t.references :campaign, index: true
      t.timestamps
    end

    create_table :triggers do |t|
      t.references :campaign, index: true
      t.integer    :trigger_type, :limit => 1
      t.string     :keyword
      t.text       :data
      t.integer    :step_numb, :limit => 1
      t.timestamps
    end

    create_table :triggeractions do |t|
      t.references :trigger, index: true
      t.integer    :action_type, :limit => 1
      t.text       :data
      t.timestamps
    end

    create_table :campaigncontacts do |t|
      t.references :contact, index: true
      t.references :campaign, index: true
      t.references :trigger, index: true, default: 0
      t.timestamps
    end

    change_table :twmessages do |t|
      t.string  :status
      t.integer :price
      t.string  :error_code
      t.string  :error_message
      t.string  :from_state
      t.string  :from_zip, :limit => 10
      t.string  :from_city
    end

    add_index :campaigns, :name
  	add_index :triggers, :keyword
    add_index :triggers, :step_numb

    add_index :clients, :name
    add_index :contacts, :lastname
    add_index :contacts, :firstname
    add_index :users, :lastname
    add_index :users, :firstname

    add_foreign_key :triggeractions, :triggers
    add_foreign_key :triggers, :campaigns
    add_foreign_key :campaigns, :clients
    add_foreign_key :twnumbers, :clients
  end

  def down
    remove_foreign_key :triggeractions, :triggers
    remove_foreign_key :triggers, :campaigns
    remove_foreign_key :campaigns, :clients
    remove_foreign_key :twnumbers, :clients

    drop_table :campaigns
    drop_table :campaignusers
    drop_table :triggers
    drop_table :triggeractions
    drop_table :campaigncontacts

    change_table :twmessages do |t|
      t.remove :status
      t.remove :price
      t.remove :error_code
      t.remove :error_message
      t.remove :from_state
      t.remove :from_zip
      t.remove :from_city
    end

    remove_index :clients, :name
    remove_index :contacts, :lastname
    remove_index :contacts, :firstname
    remove_index :users, :lastname
    remove_index :users, :firstname
  end
end
