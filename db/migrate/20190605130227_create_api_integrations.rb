class CreateApiIntegrations < ActiveRecord::Migration[5.2]

	def up
		create_table :client_api_integrations do |t|
			t.references :client, foreign_key: {on_delete: :cascade}
			t.string     :target,          default: "",           null: false,     index: true
			t.string     :name,            default: "",           null: false,     index: true
			t.string     :api_key,         default: "",           null: false
			t.text       :data,            default: {}.to_yaml,   null: false

			t.timestamps
		end

		create_table :user_api_integrations do |t|
			t.references :user, foreign_key: {on_delete: :cascade}
			t.string     :target,          default: "",           null: false,     index: true
			t.string     :name,            default: "",           null: false,     index: true
			t.string     :api_key,         default: "",           null: false
			t.text       :data,            default: {}.to_yaml,   null: false

			t.timestamps
		end

		User.all.each do |user|

			if user.google_calendar_id.length > 0
				user.user_api_integrations.new( target: "google", name: "calendar", data: { id: user.google_calendar_id } )
				user.save
			end


			YAML.load(user.zapier_subscriptions).each do |url, type|
				user.user_api_integrations.new( target: "zapier", name: type, data: { url: url } )
				user.save
			end
		end

		# remove_column :users, :google_calendar_id
		# remove_column :users, :zapier_subscriptions
	end

	def down
		# add_column :users, :google_calendar_id,   :string, default: "",         null: false
		# add_column :users, :zapier_subscriptions, :text,   default: {}.to_yaml, null: false

		UserApiIntegration.all.each do |api_integration|
			if api_integration.target.downcase == "zapier"
				zapier_subscriptions = YAML.load(api_integration.user.zapier_subscriptions)
				api_integration.user.zapier_subscriptions = ( zapier_subscriptions.merge( { api_integration.data[:url] => "receive_new_contact" } ) ).to_yaml
				api_integration.user.save
			end

			if api_integration.target.downcase == "google" && api_integration.name.downcase == "calendar"
				api_integration.user.google_calendar_id = api_integration.data[:id]
				api_integration.user.save
			end
		end

		drop_table :client_api_integrations
		drop_table :user_api_integrations
	end
end
