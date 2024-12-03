class UpdateOnboardingScheduled < ActiveRecord::Migration[5.2]
  def up
  	Client.all.each do |client|
  		client.onboarding_scheduled = client.created_at
  		client.save
  	end
  end

  def down
  	Client.all.each do |client|
	  	client.data.delete(:onboarding_scheduled)
	  end
  end
end
