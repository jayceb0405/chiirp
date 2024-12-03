class AddEndedReasonToAiAgentSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :aiagent_sessions, :ended_reason, :integer, default: 0, null: false
  end
end
