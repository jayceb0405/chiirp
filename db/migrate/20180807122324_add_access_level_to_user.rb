class AddAccessLevelToUser < ActiveRecord::Migration[5.2]
  def up
    change_table :users do |t|
      t.integer :access_level, default: 0
    end
  end

  def down
    change_table :users do |t|
      t.remove :access_level
    end
  end
end
