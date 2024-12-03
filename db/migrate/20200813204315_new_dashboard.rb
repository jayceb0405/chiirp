class NewDashboard < ActiveRecord::Migration[5.2]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Updating Dashboards..." do
			UserSetting.where( controller_action: "users_dashboard" ).find_each do |user_setting|

				# split out the "dashboard_cal_tasks"
				UserSetting.create(
					user_id: user_setting.user_id,
					controller_action: "dashboard_cal_tasks",
					name: "",
					data: {
						cal_default_view: ( user_setting.data.dig(:cal_default_view) || "agendaDay" ).to_s,
						all_tasks: ( user_setting.data.dig(:all_tasks) || 0 ).to_i,
						my_tasks: ( user_setting.data.dig(:my_tasks) || 0 ).to_i
					},
					created_at: Time.current,
					updated_at: Time.current,
					current: 1
				)

				# rename some buttons
				current_dashboard_buttons = ( user_setting.data.dig(:dashboard_buttons) || [] )

				if user_setting.user.client.tenant == "upflow"
					current_dashboard_buttons = ["upflow_kpi_stats", "upflow_invoices", "upflow_budget"] + current_dashboard_buttons
				end

				current_dashboard_buttons.each_index do |index|
					
					if current_dashboard_buttons[index].include?("tag_client")
						current_dashboard_buttons[index] = current_dashboard_buttons[index].gsub("tag_client", "client_tag")
					elsif current_dashboard_buttons[index].include?("tag_user")
						current_dashboard_buttons[index] = current_dashboard_buttons[index].gsub("tag_user", "user_tag")
					elsif current_dashboard_buttons[index].include?("trackable_link")
						current_dashboard_buttons[index] = current_dashboard_buttons[index].gsub("trackable_link", "client_trackable_link")
					elsif current_dashboard_buttons[index].include?("group_applied")
						current_dashboard_buttons[index] = current_dashboard_buttons[index].gsub("group_applied", "client_group")
					elsif current_dashboard_buttons[index].include?("campaign_completed")
						current_dashboard_buttons[index] = current_dashboard_buttons[index].gsub("campaign_completed", "client_campaign")
					end
				end

				# split up dashboard_buttons greater than max 15 buttons
				button_group_count = 1

				while current_dashboard_buttons.length > 15
					new_dashboard_buttons = current_dashboard_buttons[15,15]

					# create new "dashboard_buttons" for buttons over maximum 15
					UserSetting.create(
						user_id: user_setting.user_id,
						controller_action: "dashboard_buttons",
						name: "My Dashboard #{button_group_count}",
						data: {
							from: user_setting.data.dig(:from).to_s,
							to: user_setting.data.dig(:to).to_s,
							dynamic: ( user_setting.data.dig(:dynamic) || "l30" ).to_s,
							dashboard_buttons: new_dashboard_buttons,
							buttons_user_id: user_setting.user_id
						},
						created_at: Time.current,
						updated_at: Time.current,
						current: 0
					)

					current_dashboard_buttons = current_dashboard_buttons - new_dashboard_buttons
					button_group_count += 1
				end

				# save updated "dashboard_buttons"
				user_setting.controller_action = "dashboard_buttons"
				user_setting.name = "My Dashboard"
				user_setting.current = 1
				user_setting.data[:buttons_user_id] = user_setting.user_id
				user_setting.data[:dashboard_buttons] = current_dashboard_buttons

				user_setting.data.delete(:cal_default_view)
				user_setting.data.delete(:all_tasks)
				user_setting.data.delete(:my_tasks)
				user_setting.data.delete(:user)
				user_setting.data.delete(:client)
				user_setting.save
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end

  def down
  end
end
