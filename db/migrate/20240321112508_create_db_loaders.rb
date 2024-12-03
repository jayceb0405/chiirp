class CreateDbLoaders < ActiveRecord::Migration[7.1]
  def change
    create_table :db_loaders do |t|
      t.string :key, null: false
      t.datetime :last_start_at
      t.datetime :last_stop_at

      t.timestamps

      t.index :key, unique: true
    end
  end
end
