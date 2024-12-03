class AddClientFeatureAccessibility < ActiveRecord::Migration[5.2]
  def up
  	ActiveRecord::Base.record_timestamps = false

  	Client.all.each do |c|
  		if c.data.include?("pkg_max_phone_numbers")
	  		c.data["max_phone_numbers"] = c.data["pkg_max_phone_numbers"]
	  		c.data.delete("pkg_max_phone_numbers")
	  	else
	  		c.data["max_phone_numbers"] = 1
	  	end

  		if c.data.include?("pkg_phone_calls_allowed")
	  		c.data["phone_calls_allowed"] = c.data["pkg_phone_calls_allowed"]
	  		c.data.delete("pkg_phone_calls_allowed")
	  	else
	  		c.data["phone_calls_allowed"] = 0
	  	end

  		if c.data.include?("pkg_rvm_allowed")
	  		c.data["voice_recording_count"] = ( c.data["pkg_rvm_allowed"].to_i > 0 ? 5 : 0 )
	  		c.data.delete("pkg_rvm_allowed")
	  	else
	  		c.data["voice_recording_count"] = 0
	  	end

  		if c.data.include?("pkg_share_funnels_allowed")
	  		c.data["share_funnels_allowed"] = c.data["pkg_share_funnels_allowed"]
	  		c.data.delete("pkg_share_funnels_allowed")
	  	else
	  		c.data["share_funnels_allowed"] = 0
	  	end

      c.data["my_contacts_allowed"]                    = true
			c.data["message_broadcast_allowed"]              = true
			c.data["my_dialer_allowed"]                      = 1
			c.data["quick_leads_count"]                      = 5
			c.data["widgets_count"]                          = 5
			c.data["trackable_links_count"]                  = 25
			c.data["import_contacts_count"]                  = 1000
			c.data["custom_fields_count"]                    = 5
			c.data["text_message_images_allowed"]            = 1
	  	c.data["share_quick_leads_allowed"]              = ( c.data.include?("share_funnels_allowed") ? c.data["share_funnels_allowed"] : 0 )
			c.data["share_widgets_allowed"]                  = ( c.data.include?("share_funnels_allowed") ? c.data["share_funnels_allowed"] : 0 )
			c.data["my_contacts_group_actions_all_allowed"]  = 1
			c.data["max_contacts_count"]                     = -1

	  	c.save
  	end

  	Package.all.each do |p|
  		if p.package_data.include?("rvm_allowed")
	  		p.package_data["rvm_count"] = ( p.package_data["rvm_allowed"].to_i > 0 ? 5 : 0 )
	  		p.package_data.delete("rvm_allowed")
	  	else
	  		p.package_data["rvm_count"] = 0
	  	end

			p.package_data["my_contacts_allowed"]                    = 1
			p.package_data["my_dialer_allowed"]                      = 1
			p.package_data["quick_leads_count"]                      = ( p.package_data.include?("share_funnels_allowed") && p.package_data["share_widgets_allowed"].to_i > 0 ? 5 : 0 )
			p.package_data["widgets_count"]                          = ( p.package_data.include?("share_funnels_allowed") && p.package_data["share_widgets_allowed"].to_i > 0 ? 5 : 0 )
			p.package_data["trackable_links_count"]                  = ( p.package_data.include?("share_funnels_allowed") && p.package_data["share_widgets_allowed"].to_i > 0 ? 25 : 0 )
			p.package_data["import_contacts_count"]                  = ( p.package_data.include?("share_funnels_allowed") && p.package_data["share_widgets_allowed"].to_i > 0 ? 1000 : 100 )
			p.package_data["custom_fields_count"]                    = ( p.package_data.include?("share_funnels_allowed") && p.package_data["share_widgets_allowed"].to_i > 0 ? 10 : 0 )
			p.package_data["text_message_images_allowed"]            = 1
	  	p.package_data["share_quick_leads_allowed"]              = ( p.package_data.include?("share_funnels_allowed") ? p.package_data["share_funnels_allowed"] : 0 )
			p.package_data["share_widgets_allowed"]                  = ( p.package_data.include?("share_funnels_allowed") ? p.package_data["share_funnels_allowed"] : 0 )
			p.package_data["my_contacts_group_actions_all_allowed"]  = 1
			p.package_data["max_contacts_count"]                     = -1

	  	p.save
  	end

  	ActiveRecord::Base.record_timestamps = true
  end

  def down
  	ActiveRecord::Base.record_timestamps = false

  	Client.all.each do |c|
  		if c.data.include?("max_phone_numbers")
	  		c.data["pkg_max_phone_numbers"] = c.data["max_phone_numbers"]
	  		c.data.delete("max_phone_numbers")
	  	else
	  		c.data["pkg_max_phone_numbers"] = 1
	  	end

  		if c.data.include?("phone_calls_allowed")
	  		c.data["pkg_phone_calls_allowed"] = c.data["phone_calls_allowed"]
	  		c.data.delete("phone_calls_allowed")
	  	else
	  		c.data["pkg_phone_calls_allowed"] = 0
	  	end

  		if c.data.include?("rvm_count")
	  		c.data["pkg_rvm_allowed"] = ( c.data["rvm_count"].to_i > 0 ? 1 : 0 )
	  		c.data.delete("rvm_count")
	  	else
	  		c.data["pkg_rvm_allowed"] = 0
	  	end

  		if c.data.include?("share_funnels_allowed")
	  		c.data["pkg_share_funnels_allowed"] = c.data["share_funnels_allowed"]
	  		c.data.delete("share_funnels_allowed")
	  	else
	  		c.data["pkg_share_funnels_allowed"] = 0
	  	end

	  	c.data.delete("my_contacts_allowed")
	  	c.data.delete("my_dialer_allowed")
	  	c.data.delete("quick_leads_count")
	  	c.data.delete("widgets_count")
	  	c.data.delete("trackable_links_count")
	  	c.data.delete("import_contacts_count")
	  	c.data.delete("custom_fields_count")
	  	c.data.delete("text_message_images_allowed")
	  	c.data.delete("share_quick_leads_allowed")
	  	c.data.delete("share_widgets_allowed")
	  	c.data.delete("my_contacts_group_actions_all_allowed")
	  	c.data.delete("max_contacts_count")

	  	c.save
  	end

  	Package.all.each do |p|
  		if p.package_data.include?("rvm_count")
	  		p.package_data["rvm_allowed"] = ( p.package_data["rvm_count"].to_i > 0 ? 1 : 0 )
	  		p.package_data.delete("rvm_count")
	  	else
	  		p.package_data["rvm_allowed"] = 0
	  	end

			p.package_data.delete("my_contacts_allowed")
			p.package_data.delete("my_dialer_allowed")
			p.package_data.delete("quick_leads_count")
			p.package_data.delete("widgets_count")
			p.package_data.delete("trackable_links_count")
			p.package_data.delete("import_contacts_count")
			p.package_data.delete("custom_fields_count")
			p.package_data.delete("text_message_images_allowed")
	  	p.package_data.delete("share_quick_leads_allowed")
			p.package_data.delete("share_widgets_allowed")
			p.package_data.delete("my_contacts_group_actions_all_allowed")
			p.package_data.delete("max_contacts_count")

	  	p.save
  	end

  	ActiveRecord::Base.record_timestamps = true
  end
end
