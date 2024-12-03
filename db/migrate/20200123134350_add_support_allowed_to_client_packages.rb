class AddSupportAllowedToClientPackages < ActiveRecord::Migration[5.2]
  def up
  	support_allowed = { "chiirp" => ["training_videos"], "upflow" => ["training_videos", "university"] }

  	Package.find_each do |package|
  		package.update( support_allowed: support_allowed[package.tenant] )
  	end

  	Client.find_each do |client|
  		client.update( support_allowed: support_allowed[client.tenant] )
  	end
  end

  def down

  	Package.find_each do |package|
  		package.package_data.delete("support_allowed")
  		package.save
  	end

  	Client.find_each do |client|
  		client.data.delete("support_allowed")
  		client.save
  	end
  end
end
