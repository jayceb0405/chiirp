class AddExtRefIdToContacts < ActiveRecord::Migration[5.2]
  def up
		add_column     :contacts,          :ext_ref_id,        :string,            null: false,        default: ""
		add_index      :contacts,          :ext_ref_id
		add_index      :contact_phones,    :label

    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

    say_with_time "Converting Webhook internal_key:phone to phone_mobile..." do
			WebhookMap.where( internal_key: "phone" ).find_each do |webhook_map|
				webhook_map.update( internal_key: "phone_mobile" )
			end
		end

    say_with_time "Removing Contact salesrabbit_lead_id..." do
			Contact.where( "(data->>'salesrabbit_lead_id')::int <> 0" ).find_each do |contact|
				contact.data.delete("salesrabbit_lead_id")
				contact.data.delete("salesrabbit_status")
				contact.save
			end
		end

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end

  def down
		remove_column  :contacts,          :ext_ref_id
		remove_index   :contact_phones,    :label

    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

    say_with_time "Converting Webhook internal_key:phone_mobile to phone..." do
			WebhookMap.where( internal_key: "phone_mobile" ).find_each do |webhook_map|
				webhook_map.update( internal_key: "phone" )
			end
		end

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end
end
