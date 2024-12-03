class AddRetryCountToContactCampaign < ActiveRecord::Migration[5.2]
  def up
  	add_column :contact_campaigns, :retry_count, :integer, default: 0, null: false

  	Trigger.where(trigger_type: 105).each do |t|
  		ta = t.triggeractions.new(
  			action_type: 600,
  			data: {
					delay_days: '0',
					delay_hours: '0',
					delay_minutes: '0',
					safe_sun: '1',
					safe_mon: '1',
					safe_tue: '1',
					safe_wed: '1',
					safe_thu: '1',
					safe_fri: '1',
					safe_sat: '1',
					safe_start: '0',
					safe_end: '1440',
					client_custom_field_id: "fullname",
					parse_text_respond: 0,
					parse_text_notify: 0,
					parse_text_text: 0
				}
  		)

  		if ta.save
	  		ActiveRecord::Base.record_timestamps = false

	  		t.triggeractions.each do |ta|
	  			new_triggeraction = ta.dup
	  			new_triggeraction.created_at = ta.created_at
	  			new_triggeraction.updated_at = ta.updated_at

	  			if new_triggeraction.save
	  				DelayedJob.where(triggeraction_id: ta.id).update_all(triggeraction_id: new_triggeraction.id)
	  				CompletedTriggeraction.where(triggeraction_id: ta.id).update_all(triggeraction_id: new_triggeraction.id)
	  				Twmessage.where(triggeraction_id: ta.id).update_all(triggeraction_id: new_triggeraction.id)
	  				ta.destroy
	  			end
	  		end

	  		ActiveRecord::Base.record_timestamps = true
	  	end
  	end
  end

  def down
  	remove_column :contact_campaigns, :retry_count

  	Triggeraction.where(action_type: 600).destroy_all
  end
end
