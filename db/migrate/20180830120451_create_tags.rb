class CreateTags < ActiveRecord::Migration[5.2]
  def up
    create_table :tags do |t|
      t.string     :name
      t.references :user, index: true
      t.references :client, index: true

      t.timestamps
    end
 
    create_table :contacttags do |t|
      t.references :contact, index: true
      t.references :tag, index: true
      t.timestamps
    end

    add_index :tags, :name
 end

	def down
    drop_table :tags
    drop_table :contacttags
	end
end
