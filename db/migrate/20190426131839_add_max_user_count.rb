class AddMaxUserCount < ActiveRecord::Migration[5.2]
	def up
		ActiveRecord::Base.record_timestamps = false

		Client.all.each do |c|
			c.data["max_users_count"] = 5
			c.save
		end

		Package.all.each do |p|
			p.package_data["max_users_count"] = p.package_data["max_phone_numbers"].to_i
			p.save
		end

		User.all.each do |u|
			u.data["edit_tags"]   = (u.access_level.to_i >= 5 ? 1 : 0)
			u.data["edit_groups"] = (u.access_level.to_i >= 5 ? 1 : 0)
			u.save
		end

		ActiveRecord::Base.record_timestamps = true

		Tag.where.not(user_id: nil).each do |t|
			user = User.find_by_id(t.user_id)

			if user
				client_tag = Tag.where( client_id: user.client_id, name: t.name ).first

				if client_tag

					Contacttag.where(tag_id: t.id).each do |ct|
						ct.update(tag_id: client_tag.id)
					end

					t.destroy
				else
					t.update(user_id: nil, client_id: user.client_id)
				end
			else
				t.destroy
			end
		end

    create_table :groups do |t|
      t.references :client, index: true
      t.string     :name
      t.integer    :dashboard, default: 0, null: false

      t.timestamps
    end

    add_reference :client_widgets, :group, index: true, null: false, default: 0
    add_reference :contacts, :group, index: true, null: false, default: 0
    add_reference :trackable_links, :group, index: true, null: false, default: 0
    add_reference :user_contact_forms, :group, index: true, null: false, default: 0
    add_reference :webhooks, :group, index: true, null: false, default: 0
		remove_reference :tags, :user
    add_index :groups, :name
	end

	def down
		ActiveRecord::Base.record_timestamps = false

		Client.all.each do |c|
			c.data.delete("max_users_count")
			c.save
		end

		Package.all.each do |p|
			p.package_data.delete("max_users_count")
			p.save
		end

		User.all.each do |u|
			u.data.delete("edit_tags")
			u.data.delete("edit_groups")
			u.save
		end

    add_reference :tags, :user, null: true, default: nil, index: true
    remove_reference :client_widgets, :group
    remove_reference :contacts, :group
    remove_reference :trackable_links, :group
    remove_reference :user_contact_forms, :group
    remove_reference :webhooks, :group
    drop_table :groups
	end
end
