class CreateQuickResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :quick_responses do |t|
      t.references :client, null: false, foreign_key: true
      t.text :message
      t.string :name

      t.timestamps
    end
  end
end
