class RenameContactAiagents < ActiveRecord::Migration[7.0]
  def change
    change_column :contact_aiagents, :contact_id, :bigint, null: true
    change_column :contact_aiagents, :aiagent_id, :bigint, null: true
    
    rename_table :contact_aiagents, :aiagent_sessions

    rename_column :messages, :contact_aiagent_id, :aiagent_session_id
    add_foreign_key :messages, :aiagent_sessions

    rename_index :aiagent_sessions, :contact_aiagents_active_sessions, :active_aiagent_sessions

    change_table :aiagents do |t|
      t.string :aiagent_type, null: :false, default: 'gpt-3.5-turbo'
      t.index :data, using: :gin
    end

    change_table :aiagent_sessions do |t|
      t.jsonb :data, default: {}, null: false
      t.index :data, using: :gin
      t.string :aiagent_type, null: false, default: 'gpt-3.5-turbo'
      t.string :type, null: false, default: 'Aiagent::SmsSession'

      t.index :type
      t.index [:contact_id, :aiagent_id, :ended_at], unique: true, name: 'contact_aiagent_ended_at_index'
    end
    
    create_table :aiagent_messages do |t|
      t.belongs_to :aiagent_session, foreign_key: true, null: false
      t.belongs_to :message, foreign_key: true, null: true
      t.string :role, null: false
      t.text :content
      t.string :function_name
      t.jsonb :function_params, default: {}, null: false
      t.index :function_params, using: :gin
      t.jsonb :raw_post, default: {}, null: false
      t.index :raw_post, using: :gin

      t.timestamps
    end
  end
end
