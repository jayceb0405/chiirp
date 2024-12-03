class CreateTwmessageAttachments < ActiveRecord::Migration[5.2]
  def self.up
    create_table :twmessage_attachments do |t|
      t.references :twmessage, foreign_key: true
      t.string :media_url

      t.timestamps
    end
  end

  def self.down
		drop_table :twmessage_attachments
  end
end
