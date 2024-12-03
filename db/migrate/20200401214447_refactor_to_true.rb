class RefactorToTrue < ActiveRecord::Migration[5.2]
  def up
  	Client.find_each do |client|
  		client.update(
  			active: client.active.to_i == 1,
  			unlimited: client.unlimited.to_i == 1,
  			auto_recharge: client.auto_recharge.to_i == 1,
  			agency_access: client.agency_access.to_i == 1,
  			message_central_allowed: client.my_contacts_allowed.to_i == 1,
  			my_contacts_allowed: client.my_contacts_allowed.to_i == 1,
  			my_dialer_allowed: false,
  			user_chat_allowed: client.user_chat_allowed.to_i == 1,
  			my_contacts_group_actions_all_allowed: client.my_contacts_group_actions_all_allowed.to_i == 1,
  			phone_calls_allowed: client.phone_calls_allowed.to_i == 1,
  			text_message_images_allowed: client.text_message_images_allowed.to_i == 1,
  			share_funnels_allowed: client.share_funnels_allowed.to_i == 1,
  			share_quick_leads_allowed: client.share_quick_leads_allowed.to_i == 1,
  			share_widgets_allowed: client.share_widgets_allowed.to_i == 1
  		)
  	end

  	User.find_each do |user|
  		user.update(
  			edit_tags: user.edit_tags.is_a?(Boolean) ? user.edit_tags : user.edit_tags.to_i == 1,
  			edit_groups: user.edit_groups.is_a?(Boolean) ? user.edit_groups : user.edit_groups.to_i == 1,
  			incoming_call_popup: user.incoming_call_popup.is_a?(Boolean) ? user.incoming_call_popup : user.incoming_call_popup.to_i == 1,
  			phone_in_with_action: user.phone_in_with_action.is_a?(Boolean) ? user.phone_in_with_action : user.phone_in_with_action.to_i == 1,
  			tasks_notify_by_push: user.tasks_notify_by_push.is_a?(Boolean) ? user.tasks_notify_by_push : user.tasks_notify_by_push.to_i == 1,
  			tasks_notify_by_text: user.tasks_notify_by_text.is_a?(Boolean) ? user.tasks_notify_by_text : user.tasks_notify_by_text.to_i == 1,
  			tasks_notify_created: user.tasks_notify_created.is_a?(Boolean) ? user.tasks_notify_created : user.tasks_notify_created.to_i == 1,
  			tasks_notify_updated: user.tasks_notify_updated.is_a?(Boolean) ? user.tasks_notify_updated : user.tasks_notify_updated.to_i == 1
  		)
  	end

  	Package.find_each do |package|
  		package.update(
  			message_central_allowed: package.my_contacts_allowed.to_i == 1,
  			my_contacts_allowed: package.my_contacts_allowed.to_i == 1,
  			my_dialer_allowed: false,
  			user_chat_allowed: package.user_chat_allowed.to_i == 1,
  			my_contacts_group_actions_all_allowed: package.my_contacts_group_actions_all_allowed.to_i == 1,
  			phone_calls_allowed: package.phone_calls_allowed.to_i == 1,
  			text_message_images_allowed: package.text_message_images_allowed.to_i == 1,
  			share_funnels_allowed: package.share_funnels_allowed.to_i == 1,
  			share_quick_leads_allowed: package.share_quick_leads_allowed.to_i == 1,
  			share_widgets_allowed: package.share_widgets_allowed.to_i == 1
  		)
  	end
  end

  def down
  	Client.find_each do |client|
  		client.data.delete("message_central_allowed")

  		client.update(
  			active: client.active ? 1 : 0,
  			unlimited: client.unlimited ? 1 : 0,
  			auto_recharge: client.auto_recharge ? 1 : 0,
  			agency_access: client.agency_access ? 1 : 0,
  			my_contacts_allowed: client.my_contacts_allowed ? 1 : 0,
  			my_dialer_allowed: client.my_dialer_allowed ? 1 : 0,
  			user_chat_allowed: client.user_chat_allowed ? 1 : 0,
  			my_contacts_group_actions_all_allowed: client.my_contacts_group_actions_all_allowed ? 1 : 0,
  			phone_calls_allowed: client.phone_calls_allowed ? 1 : 0,
  			text_message_images_allowed: client.text_message_images_allowed ? 1 : 0,
  			share_funnels_allowed: client.share_funnels_allowed ? 1 : 0,
  			share_quick_leads_allowed: client.share_quick_leads_allowed ? 1 : 0,
  			share_widgets_allowed: client.share_widgets_allowed ? 1 : 0
  		)
  	end

  	User.find_each do |user|
  		user.update(
  			edit_tags: user.edit_tags ? 1 : 0,
  			edit_groups: user.edit_groups ? 1 : 0,
  			incoming_call_popup: user.incoming_call_popup ? 1 : 0,
  			phone_in_with_action: user.phone_in_with_action ? 1 : 0,
  			tasks_notify_by_push: user.tasks_notify_by_push ? 1 : 0,
  			tasks_notify_by_text: user.tasks_notify_by_text ? 1 : 0,
  			tasks_notify_created: user.tasks_notify_created ? 1 : 0,
  			tasks_notify_updated: user.tasks_notify_updated ? 1 : 0
  		)
  	end

  	Package.find_each do |package|
  		package.update(
  			my_contacts_allowed: package.my_contacts_allowed ? 1 : 0,
  			my_dialer_allowed: package.my_dialer_allowed ? 1 : 0,
  			user_chat_allowed: package.user_chat_allowed ? 1 : 0,
  			my_contacts_group_actions_all_allowed: package.my_contacts_group_actions_all_allowed ? 1 : 0,
  			phone_calls_allowed: package.phone_calls_allowed ? 1 : 0,
  			text_message_images_allowed: package.text_message_images_allowed ? 1 : 0,
  			share_funnels_allowed: package.share_funnels_allowed ? 1 : 0,
  			share_quick_leads_allowed: package.share_quick_leads_allowed ? 1 : 0,
  			share_widgets_allowed: package.share_widgets_allowed ? 1 : 0
  		)
  	end
  end
end
