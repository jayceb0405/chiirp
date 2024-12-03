class CreateContactApiIntegrations < ActiveRecord::Migration[5.2]
	def up
		remove_column :users, :google_calendar_id
		remove_column :users, :zapier_subscriptions

		create_table :contact_api_integrations do |t|
			t.references :contact, foreign_key: {on_delete: :cascade}
			t.string     :target,          default: "",           null: false,     index: true
			t.string     :name,            default: "",           null: false,     index: true
			t.string     :api_key,         default: "",           null: false
			t.jsonb      :data,            default: {},           null: false

			t.timestamps
		end

		Contact.where("(data->>'salesrabbit_lead_id')::int <> 0").each do |contact|
			contact.contact_api_integrations.create(
				target: "salesrabbit",
				status: contact.salesrabbit_status,
				lead_id: contact.salesrabbit_lead_id
			)
		end
  end

	def down
		drop_table :contact_api_integrations
	end
end
