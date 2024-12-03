class AddIndexToAiagents < ActiveRecord::Migration[7.0]
  def change
    change_table :aiagents do |t|
      t.index :share_code, unique: true
    end
  end
end
