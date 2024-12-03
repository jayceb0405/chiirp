class CreateUserAttachments < ActiveRecord::Migration[5.2]
  def self.up
    create_table :user_attachments do |t|
      t.references :user, foreign_key: {on_delete: :cascade}
      t.string :image

      t.timestamps
    end
  end

  def self.down
    drop_table :user_attachments
  end
end
