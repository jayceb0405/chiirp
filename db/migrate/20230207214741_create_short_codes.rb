class CreateShortCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :short_codes do |t|
      t.references :client
      t.string :code, null: false
      t.text :url, null: false

      t.index :code, unique: true

      t.timestamps
    end
  end
end
