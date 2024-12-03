class AddRangeTypeToTriggeractionResponseRange < ActiveRecord::Migration[5.2]
  def up
  	Triggeraction.where( action_type: 605 ).find_each do |triggeraction|

  		if triggeraction.data && triggeraction.data.include?(:response_range)

  			triggeraction.data[:response_range].each do |range|
  				range[:range_type] = "range" unless range.include?(:range_type)
  			end
      else

        if triggeraction.data && triggeraction.data.include?(:client_custom_field_id) && triggeraction.data[:client_custom_field_id].to_i > 0 && client_custom_field = triggeraction.trigger.campaign.client.client_custom_fields.find_by( id: triggeraction.data[:client_custom_field_id].to_i )

          if client_custom_field.var_type == "string" && client_custom_field.var_options && client_custom_field.var_options.include?(:string_options) && client_custom_field.var_options[:string_options].length > 0

            client_custom_field.string_options_as_array.each do |string_option|
              triggeraction.data["range_type_#{string_option.strip}".to_sym] = "range" unless triggeraction.data.include?("range_type_#{string_option.strip}".to_sym)
            end
          end
        end
  		end

  		triggeraction.save
  	end

    Triggeraction.where( action_type: 605 ).find_each do |triggeraction|
      triggeraction.data[:clear_field_on_invalid_response] = "0" if triggeraction.data && !triggeraction.data.include?(:clear_field_on_invalid_response)
      triggeraction.save
    end
  end

  def down
  end
end
