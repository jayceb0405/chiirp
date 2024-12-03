class ClientPackagePage < ActiveRecord::Migration[5.2]
  def up
  	Client.all.each do |client|
  		package_page = nil
  		package_id   = client.pkg_current.to_i

  		if package_id > 0
  			package_page = PackagePage.find_by( package_01_id: package_id) unless package_page
  			package_page = PackagePage.find_by( package_02_id: package_id) unless package_page
  			package_page = PackagePage.find_by( package_03_id: package_id) unless package_page

  			unless package_page
  				package_page = PackagePage.find_by( sys_default: 1 )
  				package_id   = package_page ? package_page.primary_package : nil
  			end
  		end

  		if package_id && package_page
  			client.update( pkg_current: package_id, pkg_page_current: package_page.id )
  		end
  	end

		add_column     :package_pages,     :package_04_id,     :integer,           null: false,        default: 0

		PackagePage.update_all( "package_04_id = package_03_id" )
		PackagePage.update_all( "package_03_id = package_02_id" )
		PackagePage.update_all( "package_02_id = package_01_id" )
		PackagePage.update_all( "package_01_id = 0" )
  end

  def down
  	Client.all.each do |client|
  		client.data.delete(:pkg_page_current)
  	end

		PackagePage.update_all( "package_01_id = package_02_id" )
		PackagePage.update_all( "package_02_id = package_03_id" )
		PackagePage.update_all( "package_03_id = package_04_id" )

		remove_column  :package_pages,     :package_04_id
  end
end
