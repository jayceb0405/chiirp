class AddCampaignIdToTasks < ActiveRecord::Migration[5.2]
  def up
  	add_reference  :tasks,             :campaign,          index: true,        null: false,        default: 0

  	Triggeraction.where(action_type: 700).find_each do |triggeraction|

      if triggeraction.data && triggeraction.data.is_a?(Hash)

        if triggeraction.data.include?(:user_id)
      		triggeraction.data[:assign_to]   = "user_#{triggeraction.data[:user_id]}"
          triggeraction.data.delete(:user_id)
        end
        
    		triggeraction.data[:campaign_id] = 0
      else
        triggeraction.data = {}
      end

  		triggeraction.save
  	end
  end

  def down
  	remove_reference         :tasks,             :campaign
  end
end
