class CreateTwnumberusers < ActiveRecord::Migration[5.2]
  def self.up
    create_table :twnumberusers do |t|
      t.integer :user_id
      t.integer :twnumber_id
      t.timestamps
    end

  	add_index :twnumberusers, :user_id
  	add_index :twnumberusers, :twnumber_id
  end

  def self.down
  	drop_table :twnumberusers
  end
end
