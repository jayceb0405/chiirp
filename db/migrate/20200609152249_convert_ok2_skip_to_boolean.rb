class ConvertOk2SkipToBoolean < ActiveRecord::Migration[5.2]
  def change

  	Triggeraction.all.each do |triggeraction|
  		if triggeraction.data && triggeraction.data.include?(:ok2skip)
  			triggeraction.data[:ok2skip] = ["true", "1"].include?(triggeraction.data[:ok2skip].to_s) ? true : false
  			triggeraction.save
  		end
  	end
  end
end
