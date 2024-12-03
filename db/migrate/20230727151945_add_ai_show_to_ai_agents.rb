class AddAiShowToAiAgents < ActiveRecord::Migration[7.0]
  def change
    change_table :aiagents do |t|
      t.boolean :show_ai, null: false, default: true
      t.integer :session_length, null: false, default: 0
      t.bigint :session_length_campaign_id
      t.bigint :session_length_group_id
      t.bigint :session_length_tag_id
      t.bigint :session_length_stage_id
    end
  end
end
