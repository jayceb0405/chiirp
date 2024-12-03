class ClientApiIntegrationJobsConversion < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

    say_with_time "Converting job_classifications in ClientApiIntegration..." do
  		ClientApiIntegration.where( target: "servicetitan", name: "" ).find_each do |client_api_integration|

  			if client_api_integration.data.include?("job_classifications_1")

  				client_api_integration.data["job_classifications_1"].each do |job_id, job_classification|
  					client_api_integration.data["job_classifications"][job_id] = {} unless client_api_integration.data.include?("job_classifications") && client_api_integration.data["job_classifications"].include?(job_id)
  					client_api_integration.data["job_classifications"][job_id]["primary"] = job_classification
  					client_api_integration.data["job_classifications"][job_id]["secondary"] = ""
  					client_api_integration.data["job_classifications"][job_id]["tech_dispatch_campaign_id"] = 0
  					client_api_integration.data["job_classifications"][job_id]["job_complete_campaign_id"] = 0
  				end

	  			client_api_integration.data.delete("job_classifications_1")
  			end

  			if client_api_integration.data.include?("job_classifications_2")

  				client_api_integration.data["job_classifications_2"].each do |job_id, job_classification|
  					client_api_integration.data["job_classifications"][job_id] = {} unless client_api_integration.data.include?("job_classifications") && client_api_integration.data["job_classifications"].include?(job_id)
  					client_api_integration.data["job_classifications"][job_id]["primary"] = "" unless client_api_integration.data["job_classifications"][job_id].include?("primary")
  					client_api_integration.data["job_classifications"][job_id]["secondary"] = job_classification
  					client_api_integration.data["job_classifications"][job_id]["tech_dispatch_campaign_id"] = 0
  					client_api_integration.data["job_classifications"][job_id]["job_complete_campaign_id"] = 0
  				end

  				client_api_integration.data.delete("job_classifications_2")
  			end

  			client_api_integration.data.delete("tech_dispatch_actions") if client_api_integration.data.include?("tech_dispatch_actions")

  			client_api_integration.data["job_complete_actions"].delete("campaign_id") if client_api_integration.data.include?("job_complete_actions") && client_api_integration.data["job_complete_actions"].include?("campaign_id")
  			client_api_integration.data["job_complete_actions"].delete("group_id") if client_api_integration.data.include?("job_complete_actions") && client_api_integration.data["job_complete_actions"].include?("group_id")
  			client_api_integration.data["job_complete_actions"].delete("tag_id") if client_api_integration.data.include?("job_complete_actions") && client_api_integration.data["job_complete_actions"].include?("tag_id")
  			client_api_integration.data["job_complete_actions"].delete("text_message") if client_api_integration.data.include?("job_complete_actions") && client_api_integration.data["job_complete_actions"].include?("text_message")
  			client_api_integration.data["job_complete_actions"].delete("from_phone") if client_api_integration.data.include?("job_complete_actions") && client_api_integration.data["job_complete_actions"].include?("from_phone")

  			client_api_integration.save
  		end
  	end

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

    say_with_time "Reversing job_classifications in ClientApiIntegration..." do
  		ClientApiIntegration.where( target: "servicetitan", name: "" ).find_each do |client_api_integration|

  			if client_api_integration.data.include?("job_classifications")
  				client_api_integration.data["job_classifications_1"] = {} unless client_api_integration.data.include?("job_classifications_1")
  				client_api_integration.data["job_classifications_2"] = {} unless client_api_integration.data.include?("job_classifications_2")

  				client_api_integration.data["job_classifications"].each do |job_id, job_classification|
  					client_api_integration.data["job_classifications_1"][job_id] = job_classification["primary"] if job_classification.include?("primary")
  					client_api_integration.data["job_classifications_2"][job_id] = job_classification["secondary"] if job_classification.include?("secondary")
  				end

  				client_api_integration.data.delete("job_classifications")
  			end

  			client_api_integration.data["tech_dispatch_actions"] = {} unless client_api_integration.data.include?("tech_dispatch_actions")
  			client_api_integration.data["tech_dispatch_actions"]["campaign_id"] = 0 unless client_api_integration.data["tech_dispatch_actions"].include?("campaign_id")
  			client_api_integration.data["tech_dispatch_actions"]["group_id"] = 0 unless client_api_integration.data["tech_dispatch_actions"].include?("group_id")
  			client_api_integration.data["tech_dispatch_actions"]["tag_id"] = 0 unless client_api_integration.data["tech_dispatch_actions"].include?("tag_id")
  			client_api_integration.data["tech_dispatch_actions"]["from_phone"] = "" unless client_api_integration.data["tech_dispatch_actions"].include?("from_phone")
  			client_api_integration.data["tech_dispatch_actions"]["text_message"] = "" unless client_api_integration.data["tech_dispatch_actions"].include?("text_message")
  			client_api_integration.data["tech_dispatch_actions"]["subscribe_tech"] = false unless client_api_integration.data["tech_dispatch_actions"].include?("subscribe_tech")

  			client_api_integration.data["job_complete_actions"] = {} unless client_api_integration.data.include?("job_complete_actions")
  			client_api_integration.data["job_complete_actions"]["campaign_id"] = 0 unless client_api_integration.data["job_complete_actions"].include?("campaign_id")
  			client_api_integration.data["job_complete_actions"]["group_id"]  = 0 unless client_api_integration.data["job_complete_actions"].include?("group_id")
  			client_api_integration.data["job_complete_actions"]["tag_id"] = 0 unless client_api_integration.data["job_complete_actions"].include?("tag_id")
  			client_api_integration.data["job_complete_actions"]["text_message"] = "" unless client_api_integration.data["job_complete_actions"].include?("text_message")
  			client_api_integration.data["job_complete_actions"]["from_phone"] = "" unless client_api_integration.data["job_complete_actions"].include?("from_phone")

  			client_api_integration.save
  		end
  	end

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end
end
