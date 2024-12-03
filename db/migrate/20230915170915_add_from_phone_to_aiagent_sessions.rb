class AddFromPhoneToAiagentSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :aiagent_sessions, :from_phone, :string
  end
end
