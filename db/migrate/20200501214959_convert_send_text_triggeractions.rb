class ConvertSendTextTriggeractions < ActiveRecord::Migration[5.2]
  def change
  	Triggeraction.where(action_type: [100,105]).find_each do |triggeraction|

			if triggeraction.data

	  		case triggeraction.action_type
	  		when 100
  				triggeraction.data[:send_to] = "contact"
	  		when 105

	  			if triggeraction.data.include?(:user_id) && triggeraction.data[:user_id].to_s.length > 0
	  				triggeraction.data[:send_to] = "user_#{triggeraction.data[:user_id]}"
	  			else
	  				triggeraction.data[:send_to] = "user"
	  			end
	  		end

	  		triggeraction.data.delete(:user_id) if triggeraction.data.include?(:user_id)
	  		triggeraction.action_type = 100
  			triggeraction.save
	  	end
  	end
  end
end
