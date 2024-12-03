class AddTermsAccepted < ActiveRecord::Migration[5.2]
  def up
  	Client.all.each do |client|
  		client.update( terms_accepted: 1 )
  	end
  end

  def down
  	Client.all.each do |client|
	  	client.data.delete(:terms_accepted)
	  end
  end
end
