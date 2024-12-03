class ConvertMessagesVoiceRecordingIdToNullDefault < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting voice_recording_id in Message table...' do
      # rename_column :messages, :voice_recording_id, :old_voice_recording_id
      # add_reference :messages, :voice_recording, foreign_key: { to_table: :voice_recordings }, index: false

      # Messages::Message.where.not(old_voice_recording_id: 0).find_each do |message|
      #   message.update(voice_recording_id: message.old_voice_recording_id)
      # end

      # remove_column :messages, :old_voice_recording_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting voice_recording_id in Message table...' do
      # rename_column :messages, :voice_recording_id, :old_voice_recording_id
      # add_reference :messages, :voice_recording, null: false, default: 0, to_table: :voice_recordings, index: false


      # Messages::Message.where.not(old_voice_recording_id: 0).find_each do |message|
      #   message.update(voice_recording_id: message.old_voice_recording_id)
      # end

      # remove_column :messages, :old_voice_recording_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
