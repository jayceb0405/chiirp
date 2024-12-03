class CreateApiCalls < ActiveRecord::Migration[7.1]
  def change
    create_table :client_api_calls do |t|
      t.references :client, foreign_key: true, index: true
      t.string :target
      t.string :client_api_id
      t.string :api_call

      t.timestamps
    end
  end
end
