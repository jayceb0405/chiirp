class NewDashboardBoxes < ActiveRecord::Migration[5.2]
  def up
  	add_column :tags, :dashboard, :integer, default: 0, null: false
  	add_column :voice_mail_recordings, :dashboard, :integer, default: 0, null: false
  	add_reference :twmessages, :voice_mail_recording, index: true, default: 0

    vmr_hash = VoiceMailRecording.all.collect { |vmr| [ "Ringless VM: " + vmr.name, vmr.id ]}.to_h

    Twmessage.where("message like ?", "%Ringless VM: %").each do |t|
      t.update(voice_mail_recording_id: ( vmr_hash[t.message] || 0 ))
    end
  end

  def down
  	remove_column :tags, :dashboard
  	remove_column :voice_mail_recordings, :dashboard
  	remove_reference :twmessages, :voice_mail_recording
  end
end
