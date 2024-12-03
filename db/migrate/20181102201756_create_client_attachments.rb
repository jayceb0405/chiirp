class CreateClientAttachments < ActiveRecord::Migration[5.2]
  def self.up
    create_table :client_attachments do |t|
      t.references :client, foreign_key: true
      t.string :image

      t.timestamps
    end
  end

  def self.down
    drop_table :client_attachments
  end
end
