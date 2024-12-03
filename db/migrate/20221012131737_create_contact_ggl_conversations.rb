class CreateContactGglConversations < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ContactGglConversaions table...' do
      create_table :contact_ggl_conversations do |t|
        t.references    :contact, foreign_key: true, index: true
        t.string        :agent_id, default: '', null: false
        t.string        :conversation_id, default: '', null: false

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
