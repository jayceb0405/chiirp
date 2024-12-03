class UpdateOpenAiModel < ActiveRecord::Migration[7.1]
  def up
    change_column :aiagents, :aiagent_type, :string, default: 'gpt-4o-mini'
    change_column :aiagent_sessions, :aiagent_type, :string, default: 'gpt-4o-mini', null: false
  end
end
