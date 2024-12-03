class UpdateDashboardCalendarViewType < ActiveRecord::Migration[6.0]
	def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Updating Dashboard Calendar Default View..." do

			UserSetting.where( controller_action: "dashboard_cal_tasks" ).find_each do |user_setting|

				case user_setting.data.dig(:cal_default_view).to_s
				when "month"
					user_setting.data[:cal_default_view] = "dayGridMonth"
				when "agendaWeek"
					user_setting.data[:cal_default_view] = "dayGridWeek"
				when "agendaDay"
					user_setting.data[:cal_default_view] = "timeGridDay"
				when "listMonth"
					user_setting.data[:cal_default_view] = "listWeek"
				else
					user_setting.data[:cal_default_view] = "dayGridMonth"
				end

				user_setting.save
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
	end

	def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Updating Dashboard Calendar Default View..." do

			UserSetting.where( controller_action: "dashboard_cal_tasks" ).find_each do |user_setting|

				case user_setting.data.dig(:cal_default_view).to_s
				when "dayGridMonth"
					user_setting.data[:cal_default_view] = "month"
				when "dayGridWeek"
					user_setting.data[:cal_default_view] = "agendaWeek"
				when "timeGridDay"
					user_setting.data[:cal_default_view] = "agendaDay"
				when "listWeek"
					user_setting.data[:cal_default_view] = "listMonth"
				else
					user_setting.data[:cal_default_view] = "month"
				end

				user_setting.save
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
	end
end
