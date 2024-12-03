class ModifyTriggeractionDataWithUsersHash < ActiveRecord::Migration[5.2]
  def up
  	Triggeraction.all.each do |ta|
  		if ta.data && ta.data.include?(:user_id)
  			if ta.data[:user_id].to_i > 0
  				# convert to hash
  				ta.data[:users] = { ta.data[:user_id] => 100 }
  			end

  			ta.data.delete(:user_id)
  			ta.save
  		end
  	end
  end

  def down
  	Triggeraction.all.each do |ta|
  		if ta.data && ta.data.include?(:users)
  			if ta.data[:users].keys[0].to_i > 0
  				# convert to hash
  				ta.data[:user_id] = ta.data[:users].keys[0].to_i
  			end

  			ta.data.delete(:users)
  			ta.save
  		end
  	end
  end
end
