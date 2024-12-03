class AddDefaultsToAiagent < ActiveRecord::Migration[7.0]
  def change
    change_column :aiagent_sessions, :aiagent_type, :string, default: 'gpt-3.5-turbo', null: false
    change_column :aiagent_sessions, :type, :string, default: 'Aiagent::SmsSession', null: false
  end
end
