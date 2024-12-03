class ConvertTriggeractionFromPhoneToArray < ActiveRecord::Migration[6.0]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Removing old data field from UserApiIntegrations..." do
			remove_column          :user_api_integrations, :old_data if column_exists? :user_api_integrations, :old_data
		end

		say_with_time "Creating new JsonB data field in Triggeractions..." do
			rename_column          :triggeractions,    :data,              :old_data
			add_column             :triggeractions,    :data,              :jsonb,             null: false,        default: {}
			add_index              :triggeractions,    :data,              using: :gin
		end

		Triggeraction.reset_column_information

		say_with_time "Converting old data field to new data field in Triggeractions..." do

			Triggeraction.where.not( old_data: nil ).find_each do |triggeraction|

				if triggeraction.scheduled?
					triggeraction.delay_days                                        = triggeraction.old_data.dig(:delay_days).to_i
					triggeraction.delay_hours                                       = triggeraction.old_data.dig(:delay_hours).to_i
					triggeraction.delay_minutes                                     = triggeraction.old_data.dig(:delay_minutes).to_i
					triggeraction.safe_start                                        = triggeraction.old_data.dig(:safe_start).to_i
					triggeraction.safe_end                                          = triggeraction.old_data.dig(:safe_end).to_i
					triggeraction.safe_sun                                          = triggeraction.old_data.dig(:safe_sun).to_bool
					triggeraction.safe_mon                                          = triggeraction.old_data.dig(:safe_mon).to_bool
					triggeraction.safe_tue                                          = triggeraction.old_data.dig(:safe_tue).to_bool
					triggeraction.safe_wed                                          = triggeraction.old_data.dig(:safe_wed).to_bool
					triggeraction.safe_thu                                          = triggeraction.old_data.dig(:safe_thu).to_bool
					triggeraction.safe_fri                                          = triggeraction.old_data.dig(:safe_fri).to_bool
					triggeraction.safe_sat                                          = triggeraction.old_data.dig(:safe_sat).to_bool
					triggeraction.ok2skip                                           = triggeraction.old_data.dig(:ok2skip).to_bool
				end

				case triggeraction.action_type
				when 100
					triggeraction.text_message                                    = triggeraction.old_data.dig(:text_message).to_s
					triggeraction.attachments                                     = triggeraction.old_data.dig(:attachments).to_s.split(",").map(&:to_i)
					triggeraction.from_phone                                      = [triggeraction.old_data.dig(:from_phone)]
					triggeraction.send_to                                         = triggeraction.old_data.dig(:send_to).to_s
				when 150
					triggeraction.rvm_id                                          = triggeraction.old_data.dig(:rvm_id).to_i
					triggeraction.from_phone                                      = triggeraction.old_data.dig(:from_phone).to_s
				when 170
					triggeraction.email_subject                                   = triggeraction.old_data.dig(:email_subject).to_s
					triggeraction.email_content                                   = triggeraction.old_data.dig(:email_content).to_s
					triggeraction.cc_email                                        = triggeraction.old_data.dig(:cc_email).to_s
					triggeraction.cc_name                                         = triggeraction.old_data.dig(:cc_name).to_s
					triggeraction.bcc_email                                       = triggeraction.old_data.dig(:bcc_email).to_s
					triggeraction.bcc_name                                        = triggeraction.old_data.dig(:bcc_name).to_s
				when 180
					triggeraction.text_message                                    = triggeraction.old_data.dig(:text_message).to_s
					triggeraction.slack_channel                                   = triggeraction.old_data.dig(:slack_channel).to_s
					triggeraction.attachments                                     = triggeraction.old_data.dig(:attachments).to_s.split(",").map(&:to_i)
				when 200
					triggeraction.campaign_id                                     = triggeraction.old_data.dig(:campaign_id).to_i
				when 300
					triggeraction.tag_id                                          = triggeraction.old_data.dig(:tag_id).to_i
				when 305
					triggeraction.tag_id                                          = triggeraction.old_data.dig(:tag_id).to_i
				when 350
					triggeraction.group_id                                        = triggeraction.old_data.dig(:group_id).to_i
				when 355
					triggeraction.group_id                                        = triggeraction.old_data.dig(:group_id).to_i
				when 400
					triggeraction.campaign_id                                     = triggeraction.old_data.dig(:campaign_id).to_s
					triggeraction.description                                     = triggeraction.old_data.dig(:description).to_s
				when 510
					triggeraction.assign_to                                       = triggeraction.old_data.dig(:assign_to)
					triggeraction.distribution                                    = triggeraction.old_data.dig(:distribution)
				when 550
					triggeraction.to_phone                                        = triggeraction.old_data.dig(:to_phone)
					triggeraction.from_phone                                      = triggeraction.old_data.dig(:from_phone).to_s
				when 551
					triggeraction.to_phone                                        = triggeraction.old_data.dig(:to_phone)
					triggeraction.from_phone                                      = triggeraction.old_data.dig(:from_phone).to_s
				when 600
					triggeraction.client_custom_field_id                          = triggeraction.old_data.dig(:client_custom_field_id).to_i
					triggeraction.parse_text_respond                              = triggeraction.old_data.dig(:parse_text_respond).to_bool
					triggeraction.parse_text_notify                               = triggeraction.old_data.dig(:parse_text_notify).to_bool
					triggeraction.parse_text_text                                 = triggeraction.old_data.dig(:parse_text_text).to_bool
					triggeraction.clear_field_on_invalid_response                 = triggeraction.old_data.dig(:clear_field_on_invalid_response).to_bool
					triggeraction.text_message                                    = triggeraction.old_data.dig(:text_message).to_s
					triggeraction.attachments                                     = triggeraction.old_data.dig(:attachments).to_s.split(",").map(&:to_i)
				when 605
					triggeraction.client_custom_field_id                          = triggeraction.old_data.dig(:client_custom_field_id).to_i
					triggeraction.response_range                                  = {}

					if client_custom_field = ClientCustomField.find_by( id: triggeraction.old_data.dig(:client_custom_field_id).to_i )

						if client_custom_field.var_type == "string" && !( client_custom_field.var_options.dig(:string_options) || {} ).empty?
							string_options  = client_custom_field.string_options_as_array
							string_options << "image" if client_custom_field.image_is_valid
							string_options << "empty" << "invalid"

							string_options.each do |option|
								triggeraction.response_range[option] = {
									range_type: triggeraction.old_data.dig("range_type_#{option}".to_sym).to_s,
									campaign_id: triggeraction.old_data.dig("campaign_id_#{option}".to_sym).to_i,
									group_id: triggeraction.old_data.dig("group_id_#{option}".to_sym).to_i,
									tag_id: triggeraction.old_data.dig("tag_id_#{option}".to_sym).to_i
								}
							end
						else
							count = 0

							( triggeraction.old_data.dig(:response_range) || [] ).each do |range|
								triggeraction.response_range[count.to_s] = {
									range_type: range.dig(:range_type).to_s,
									campaign_id: range.dig(:campaign_id).to_i,
									group_id: range.dig(:group_id).to_i,
									tag_id: range.dig(:tag_id).to_i,
									minimum: [range.dig(:minimum).to_i, range.dig("minimum").to_i].max.to_i,
									maximum: [range.dig(:maximum).to_i, range.dig("maximum").to_i].max.to_i
								}
								count += 1
							end
						end
					end
				when 610
					triggeraction.client_custom_field_id                          = triggeraction.old_data.dig(:client_custom_field_id).to_s
					triggeraction.description                                     = triggeraction.old_data.dig(:description).to_s
				when 700
					triggeraction.name                                            = triggeraction.old_data.dig(:name).to_s
					triggeraction.assign_to                                       = triggeraction.old_data.dig(:assign_to).to_s
					triggeraction.description                                     = triggeraction.old_data.dig(:description).to_s
					triggeraction.campaign_id                                     = triggeraction.old_data.dig(:campaign_id).to_i
					triggeraction.due_delay_days                                  = triggeraction.old_data.dig(:due_delay_days).to_i
					triggeraction.due_delay_hours                                 = triggeraction.old_data.dig(:due_delay_hours).to_i
					triggeraction.due_delay_minutes                               = triggeraction.old_data.dig(:due_delay_minutes).to_i
					triggeraction.dead_delay_days                                 = triggeraction.old_data.dig(:dead_delay_days).to_i
					triggeraction.dead_delay_hours                                = triggeraction.old_data.dig(:dead_delay_hours).to_i
					triggeraction.dead_delay_minutes                              = triggeraction.old_data.dig(:dead_delay_minutes).to_i
				when 750
					triggeraction.user_id                                         = triggeraction.old_data.dig(:user_id).to_s
					triggeraction.send_to                                         = triggeraction.old_data.dig(:send_to).to_s
					triggeraction.from_phone                                      = triggeraction.old_data.dig(:from_phone).to_s
					triggeraction.group_id                                        = triggeraction.old_data.dig(:retry_count).to_i
					triggeraction.retry_count                                     = triggeraction.old_data.dig(:retry_interval).to_i
					triggeraction.stop_on_connection                              = triggeraction.old_data.dig(:stop_on_connection).to_bool
				when 800
					triggeraction.client_name_custom_field_id                     = triggeraction.old_data.dig(:client_name_custom_field_id).to_i
					triggeraction.client_package_id                               = triggeraction.old_data.dig(:client_package_id).to_i
				end

				triggeraction.save
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end

  def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Creating old data field in UserApiIntegrations..." do

			unless column_exists? :user_api_integrations, :old_data
				add_column             :user_api_integrations, :old_data,      :text,              null: false,        default: {}.to_yaml
			end
		end

		say_with_time "Renaming old data field in Triggeractions..." do

			if column_exists? :triggeractions, :old_data
				remove_column          :triggeractions,    :data
				rename_column          :triggeractions,    :old_data,          :data
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end
end
