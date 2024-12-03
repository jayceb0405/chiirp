class ConvertUserApiIntegrationDataToJson < ActiveRecord::Migration[5.2]
	def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Removing phone fields in Contacts..." do
			remove_column          :contacts,          :phone
			remove_column          :contacts,          :alt_phone
		end

		say_with_time "Creating new data field in UserApiIntegrations..." do
			remove_column          :user_api_integrations, :old_data if column_exists? :user_api_integrations, :old_data
			rename_column          :user_api_integrations, :data,          :old_data
			add_column             :user_api_integrations, :data,          :jsonb,             null: false,        default: {}
			add_index              :user_api_integrations, :data,          using: :gin
		end

		say_with_time "Converting old data field to new data field in UserApiIntegrations..." do

			UserApiIntegration.find_each do |user_api_integration|

				if user_api_integration.target == "google" && user_api_integration.name == "calendar"
					user_api_integration.google_calendar_id = user_api_integration.data[:id] if user_api_integration.data.include?(:id)
				elsif user_api_integration.target == "zapier"
					user_api_integration.zapier_subscription_url = user_api_integration.data[:url] if user_api_integration.data.include?(:url)
				end

				user_api_integration.save
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
	end

	def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Adding phone fields in Contacts..." do
			add_column             :contacts,          :phone,             :string,            null: false,        default: ""
			add_column             :contacts,          :alt_phone,         :string,            null: false,        default: ""
			add_index              :contacts,          :phone
			add_index              :contacts,          :alt_phone
		end

		say_with_time "Creating old data field in UserApiIntegrations..." do
			remove_column          :user_api_integrations, :old_data if column_exists? :user_api_integrations, :old_data
			add_column             :user_api_integrations, :old_data,      :text,              null: false,        default: {}.to_yaml
		end

		say_with_time "Converting new data field to old data field in UserApiIntegrations..." do

			UserApiIntegration.find_each do |user_api_integration|

				if user_api_integration.target == "google" && user_api_integration.name == "calendar"
					user_api_integration.old_data[:id] = user_api_integration.google_calendar_id if user_api_integration.data.include?(:id)
				elsif user_api_integration.target == "zapier"
					user_api_integration.old_data[:url] = user_api_integration.zapier_subscription_url if user_api_integration.data.include?(:url)
				end

				user_api_integration.save
			end
		end

		say_with_time "Renaming old data field in UserApiIntegrations..." do
			rename_column          :user_api_integrations, :data,          :new_data
			rename_column          :user_api_integrations, :old_data,      :data
			rename_column          :user_api_integrations, :new_data,      :old_data
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
	end
end
