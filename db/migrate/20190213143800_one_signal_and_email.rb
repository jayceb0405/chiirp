class OneSignalAndEmail < ActiveRecord::Migration[5.2]
  def up
    create_table :push_users do |t|
      t.references :user, foreign_key: true
      t.string  :player_id, null: false, default: ""

			t.timestamps
    end

		add_column :contacts, :ok2email, :string, default: "0"

		# set all Contacts to allow emails
		Contact.update_all(ok2email: "1")

    remove_foreign_key :trackable_links, :campaigns
    remove_foreign_key :trackable_links, :tags
  end

  def down
  	drop_table :push_users
  	remove_column :contacts, :ok2email
    add_foreign_key :trackable_links, :tags, on_delete: :cascade
    add_foreign_key :trackable_links, :campaigns
  end
end
