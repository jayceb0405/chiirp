class ModifyTriggeraction600ToIncludeResponseText < ActiveRecord::Migration[5.2]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Converting Invalid Text Responses in Triggeractions..." do
			Triggeraction.where( action_type: 600 ).find_each do |triggeraction|

				if triggeraction.data && triggeraction.data.dig(:parse_text_respond).to_i == 1
					client_custom_field_id = triggeraction.data.dig(:client_custom_field_id).to_s
					text_message = "I'm sorry \#{contact.firstname}, I didn't catch your response."

					if ["firstname", "lastname", "fullname", "address1", "address2", "city", "state", "zipcode", "email", "brand-notes"].include?(client_custom_field_id)
						# do nothing
					elsif client_custom_field_id == "birthdate"
						triggeraction.data[:text_message] = text_message + " I was expecting a date."
					elsif client_custom_field_id[0,6] == "phone_"
						triggeraction.data[:text_message] = text_message + " That doesn't look like a valid phone number. Could you restate that?"
					else

						if client_custom_field = ClientCustomField.find_by( id: client_custom_field_id.to_i )

							case client_custom_field.var_type
							when "string"
								triggeraction.data[:text_message] = text_message + " Was that #{client_custom_field.string_options_as_array.join(", ").reverse.sub(" ,", " ro ").reverse}?"
							when "numeric"
								triggeraction.data[:text_message] = text_message + " I was expecting a number between #{client_custom_field.var_options[:numeric_min]} and #{client_custom_field.var_options[:numeric_max]}."
							when "stars"
								triggeraction.data[:text_message] = text_message + " I was expecting a number between 0 and #{client_custom_field.var_options[:stars_max].to_i.to_s}."
							when "currency"
								triggeraction.data[:text_message] = text_message + " I was expecting a dollar value between #{ActionController::Base.helpers.number_to_currency(client_custom_field.var_options[:currency_min])} and #{ActionController::Base.helpers.number_to_currency(client_custom_field.var_options[:currency_max])}."
							when "date"
								triggeraction.data[:text_message] = text_message + " I was expecting a date."
							end
						end
					end
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

		say_with_time "Reverting Invalid Text Responses in Triggeractions..." do
			Triggeraction.where( action_type: 600 ).find_each do |triggeraction|

				if triggeraction.data.include?(:text_message)
					triggeraction.data.delete(:text_message)
					triggeraction.save
				end
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end
end
