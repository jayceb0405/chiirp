class RemoveClientPkgPrefix < ActiveRecord::Migration[5.2]
  def up
  	Client.all.each do |client|
  		client.data["mo_charge"]            = client.data["pkg_mo_charge"].to_d if client.data.include?("pkg_mo_charge")
  		client.data["mo_credits"]           = client.data["pkg_mo_credits"].to_d if client.data.include?("pkg_mo_credits")
  		client.data["trial_days"]           = client.data["pkg_trial_days"].to_d if client.data.include?("pkg_trial_days")
  		client.data["trial_credits"]        = client.data["pkg_trial_credits"].to_d if client.data.include?("pkg_trial_credits")
  		client.data["credit_charge"]        = client.data["pkg_credit_charge"].to_d if client.data.include?("pkg_credit_charge")
  		client.data["text_message_credits"] = client.data["pkg_text_message_credits"].to_d if client.data.include?("pkg_text_message_credits")
  		client.data["text_image_credits"]   = client.data["pkg_text_image_credits"].to_d if client.data.include?("pkg_text_image_credits")
  		client.data["phone_call_credits"]   = client.data["pkg_phone_call_credits"].to_d if client.data.include?("pkg_phone_call_credits")
  		client.data["rvm_credits"]          = client.data["pkg_rvm_credits"].to_d if client.data.include?("pkg_rvm_credits")
  		client.data["package_id"]           = client.data["pkg_current"].to_i if client.data.include?("pkg_current")
  		client.data["package_page_id"]      = client.data["pkg_page_current"].to_i if client.data.include?("pkg_page_current")
  		client.data.delete("pkg_mo_charge")
  		client.data.delete("pkg_mo_credits")
  		client.data.delete("pkg_trial_days")
  		client.data.delete("pkg_trial_credits")
  		client.data.delete("pkg_credit_charge")
  		client.data.delete("pkg_text_message_credits")
  		client.data.delete("pkg_text_image_credits")
  		client.data.delete("pkg_phone_call_credits")
  		client.data.delete("pkg_rvm_credits")
  		client.data.delete("pkg_current")
  		client.data.delete("pkg_page_current")

      client.data["setup_fee"] = 0.to_d

  		client.save
  	end

    Package.all.each do |package|
      package.package_data["setup_fee"] = 0.to_d
      package.save
    end
  end

  def down
  	Client.all.each do |client|
  		client.data["pkg_mo_charge"]            = client.data["mo_charge"].to_f if client.data.include?("mo_charge")
  		client.data["pkg_mo_credits"]           = client.data["mo_credits"].to_f if client.data.include?("mo_credits")
  		client.data["pkg_trial_days"]           = client.data["trial_days"].to_f if client.data.include?("trial_days")
  		client.data["pkg_trial_credits"]        = client.data["trial_credits"].to_f if client.data.include?("trial_credits")
  		client.data["pkg_credit_charge"]        = client.data["credit_charge"].to_f if client.data.include?("credit_charge")
  		client.data["pkg_text_message_credits"] = client.data["text_message_credits"].to_f if client.data.include?("text_message_credits")
  		client.data["pkg_text_image_credits"]   = client.data["text_image_credits"].to_f if client.data.include?("text_image_credits")
  		client.data["pkg_phone_call_credits"]   = client.data["phone_call_credits"].to_f if client.data.include?("phone_call_credits")
  		client.data["pkg_rvm_credits"]          = client.data["rvm_credits"].to_f if client.data.include?("rvm_credits")
  		client.data["pkg_current"]              = client.data["package_id"].to_i if client.data.include?("package_id")
  		client.data["pkg_page_current"]         = client.data["package_page_id"].to_i if client.data.include?("package_page_id")
  		client.data.delete("mo_charge")
  		client.data.delete("mo_credits")
  		client.data.delete("trial_days")
  		client.data.delete("trial_credits")
  		client.data.delete("credit_charge")
  		client.data.delete("text_message_credits")
  		client.data.delete("text_image_credits")
  		client.data.delete("phone_call_credits")
  		client.data.delete("rvm_credits")
  		client.data.delete("package_id")
  		client.data.delete("package_page_id")

      client.data.delete("setup_fee")

  		client.save
  	end

    Package.all.each do |package|
      package.package_data.delete("setup_fee")
      package.save
    end
  end
end
