class AddMaxFunnels < ActiveRecord::Migration[5.2]
	def up
		ActiveRecord::Base.record_timestamps = false

		Client.all.each do |c|
			c.data["campaigns_count"] = ( c.data.include?("share_funnels_allowed") && c.data["share_funnels_allowed"].to_i > 0 ? 25 : 0 )
			c.save
		end

		Package.all.each do |p|
			p.package_data["campaigns_count"] = ( p.package_data.include?("share_funnels_allowed") && p.package_data["share_funnels_allowed"].to_i > 0 ? 25 : 0 )
			p.save
		end

		ActiveRecord::Base.record_timestamps = true
	end

	def down
		ActiveRecord::Base.record_timestamps = false

		Client.all.each do |c|
			c.data.delete("campaigns_count")
			c.save
		end

		Package.all.each do |p|
			p.package_data.delete("campaigns_count")
			p.save
		end

		ActiveRecord::Base.record_timestamps = true
	end
end
