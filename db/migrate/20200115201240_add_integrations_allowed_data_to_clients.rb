class AddIntegrationsAllowedDataToClients < ActiveRecord::Migration[5.2]
  def up
  	integrations_allowed = { "chiirp" => ["maestro", "salesrabbit", "xencall", "zapier"], "upflow" => ["servicetitan", "xencall", "zapier"] }

  	Package.find_each do |package|
  		package.update( integrations_allowed: integrations_allowed[package.tenant] )
  	end

  	Client.find_each do |client|
  		client.update( integrations_allowed: integrations_allowed[client.tenant] )
  	end
  end

  def down

  	Package.find_each do |package|
  		package.data.delete("integrations_allowed")
  		package.save
  	end

  	Client.find_each do |client|
  		client.data.delete("integrations_allowed")
  		client.save
  	end
  end
end
