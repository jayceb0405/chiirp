class AddTenantToClient < ActiveRecord::Migration[5.2]
  def up
		add_column     :clients,           :tenant,            :string,            null: false,        default: ""
    add_column     :packages,          :tenant,            :string,            null: false,        default: ""
    add_column     :package_pages,     :tenant,            :string,            null: false,        default: ""

		Client.update_all(tenant: "chiirp")
    Package.update_all(tenant: "chiirp")
    PackagePage.update_all(tenant: "chiirp")

  	ClientApiIntegration.where(target: "servicetitan").each do |client_api_integration|
  		client_api_integration.data["tenant_api_key"] = client_api_integration.data["chiirp_api_key"] if client_api_integration.data.include?("chiirp_api_key")
  		client_api_integration.data.delete("chiirp_api_key")
  		client_api_integration.save
  	end

    add_index      :clients,           :tenant
    add_index      :packages,          :tenant
    add_index      :package_pages,     :tenant
  end

  def down
  	remove_column  :clients,           :tenant
    remove_column  :packages,          :tenant
    remove_column  :package_pages,     :tenant

  	ClientApiIntegration.where(target: "servicetitan").each do |client_api_integration|
  		client_api_integration.data["chiirp_api_key"] = client_api_integration.data["tenant_api_key"] if client_api_integration.data.include?("tenant_api_key")
  		client_api_integration.data.delete("tenant_api_key")
  		client_api_integration.save
  	end
  end
end
