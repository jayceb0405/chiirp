class CreateVoiceMailRecordings < ActiveRecord::Migration[5.2]
  def up
    create_table :voice_mail_recordings do |t|
      t.references :client, foreign_key: true
      t.string  :name, default: ""
      t.string  :sid, default: ""
      t.string  :url, default: ""

      t.timestamps
    end
  end

  def down
    drop_table :voice_mail_recordings
  end
end
