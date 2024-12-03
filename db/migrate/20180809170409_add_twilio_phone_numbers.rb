class AddTwilioPhoneNumbers < ActiveRecord::Migration[5.2]
  def self.up
    change_table :twmessages do |t|
      t.string :to_phone
      t.datetime :read_at
    end

    change_table :twnumbers do |t|
      t.string :name, default: ""
    end

    add_index :twmessages, :created_at, unique: true
    add_index :twmessages, :from_phone
    add_index :twmessages, :to_phone
    add_index :twnumbers, :phonenumber
  end

  def self.down
    remove_index :twmessages, :created_at
    remove_index :twmessages, :from_phone
    remove_index :twmessages, :to_phone
    remove_index :twnumbers, :phonenumber

    change_table :twmessages do |t|
      t.remove :to_phone
      t.remove :read_at
    end

    change_table :twnumbers do |t|
      t.remove :name
    end
  end
end
