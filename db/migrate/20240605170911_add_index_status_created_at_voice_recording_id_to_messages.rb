class AddIndexStatusCreatedAtVoiceRecordingIdToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :messages, [:status, :created_at, :voice_recording_id], algorithm: :concurrently
  end
end
