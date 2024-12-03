class ServiceTitanUserAssignments < ActiveRecord::Migration[5.2]
  def change

  	ClientApiIntegration.where( target: "servicetitan" ).find_each do |client_api_integration|

  		if client_api_integration.api_key.length > 0

  			if client_api_integration.data.include?("job_complete_contact_actions") && client_api_integration.data["job_complete_contact_actions"].include?(:update_balance_window_days)
  				client_api_integration.update_balance_actions[:update_balance_window_days] = client_api_integration.data["job_complete_contact_actions"][:update_balance_window_days].to_i
  				client_api_integration.data["job_complete_contact_actions"].delete("update_balance_window_days")
  			end

  			if client_api_integration.data.include?("job_complete_contact_actions")
  				client_api_integration.job_complete_actions = client_api_integration.data["job_complete_contact_actions"]
  				client_api_integration.data.delete("job_complete_contact_actions")
  			end

  			if client_api_integration.data.include?("job_complete_contact_actions_balance")
  				client_api_integration.data.delete("job_complete_contact_actions_balance")
  			end

  			if client_api_integration.data.include?("job_complete_technician_text")
  				client_api_integration.job_complete_actions.merge(client_api_integration.data["job_complete_technician_text"])
  				client_api_integration.data.delete("job_complete_technician_text")
  			end

        if client_api_integration.data.include?("user_assignments")
          client_api_integration.data.delete("user_assignments")
        end

  			client_api_integration.save
  		end
  	end
  end
end
