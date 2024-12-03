class ConvertAssignToUser < ActiveRecord::Migration[5.2]
  def change
  	Triggeraction.where(action_type: [510]).find_each do |triggeraction|

			if triggeraction.data

				if triggeraction.data.include?(:users)
					triggeraction.data[:assign_to] = {}

					triggeraction.data[:users].each do |user_id, amount|
						triggeraction.data[:assign_to]["user_#{user_id}"] = amount
					end

					triggeraction.data.delete(:users)
				end

				if triggeraction.data.include?(:user_distribution)
					triggeraction.data[:distribution] = {}

					triggeraction.data[:user_distribution].each do |user_id, amount|
						triggeraction.data[:distribution]["user_#{user_id}"] = amount
					end

					triggeraction.data.delete(:user_distribution)
				end

  			triggeraction.save
	  	end
  	end
  end
end
