class CreateContactAiagents < ActiveRecord::Migration[7.0]
  def change
    create_table :aiagents do |t|
      t.belongs_to :client, null: false, foreign_key: true
      t.belongs_to :campaign,            foreign_key: true
      t.belongs_to :group,               foreign_key: true
      t.belongs_to :tag,                 foreign_key: true
      t.belongs_to :stage,               foreign_key: true
      t.string :name
      t.text :system_prompt
      t.string :initial_prompt
      t.string :ending_prompt
      t.string :action
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end

    create_table :contact_aiagents do |t|
      t.belongs_to :contact, null: false, foreign_key: true
      t.belongs_to :aiagent, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps

      t.index :ended_at
      t.index %i[contact_id started_at ended_at], name: 'contact_aiagents_active_sessions'
    end

    change_table :messages do |t|
      t.belongs_to :contact_aiagent
    end
  end
end
