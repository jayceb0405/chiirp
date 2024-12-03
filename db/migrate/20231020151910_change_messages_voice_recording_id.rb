class ChangeMessagesVoiceRecordingId < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing voice_recording_id in Messages table...' do
      change_column_null :messages, :voice_recording_id, true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
