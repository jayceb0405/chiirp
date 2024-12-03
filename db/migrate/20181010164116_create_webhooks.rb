class CreateWebhooks < ActiveRecord::Migration[5.2]
	def up
		create_table :webhooks do |t|
			t.references :client, foreign_key: true
			t.string :name
			t.string :token
			t.string :testing
			t.text   :sample_data

			t.timestamps
		end

		create_table :webhook_maps do |t|
			t.references :webhook, foreign_key: true
			t.string :external_key
			t.string :internal_key

			t.timestamps
		end

		add_index :webhooks, :token
		add_column :contacts, :sleep, :string
		add_column :contacts, :ok2text, :string

		# assign unassigned Contacts to admin User
		Contact.update_all(ok2text: "1")
	end

	def down
		drop_table :webhook_maps
		drop_table :webhooks
		remove_column :contacts, :sleep
		remove_column :contacts, :ok2text
	end
end
