class AddMaxMessagesToAiagents < ActiveRecord::Migration[7.0]
  def change
    change_table :aiagents do |t|
      t.integer :max_messages, default: 0, null: false
      t.string :max_messages_prompt
    end
  end
end
