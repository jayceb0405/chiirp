class AddShareCodeToAiagent < ActiveRecord::Migration[7.0]
  def change
    change_table :aiagents do |t|
      t.string "share_code", default: "", null: false
      # t.index :share_code, unique: true
    end
  end
end
