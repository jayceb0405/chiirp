class ConvertUserContactFormToActiveStorage < ActiveRecord::Migration[5.2]
	def up
    change_column  :user_contact_forms, :price,             :decimal,           default: 0,         null: false

		rename_column  :user_contact_forms, :background_image,  :old_background_image
		rename_column  :user_contact_forms, :marketplace_image, :old_marketplace_image
		rename_column  :user_contact_forms, :logo_image,        :old_logo_image

		UserContactForm.all.each do |user_contact_form|

			if user_contact_form.old_background_image.present? && !user_contact_form.background_image.attached?
				begin
					say "Processing background image (UserContactForm id #{user_contact_form.id}): #{user_contact_form.old_background_image.url.inspect}"
					user_contact_form.background_image.attach(io: open(user_contact_form.old_background_image.url), filename: user_contact_form.old_background_image.filename.split("/").last)
					say "COPIED"
					user_contact_form.remove_old_background_image!
					say "DELETED"
					user_contact_form.save
					say "SAVED"
				rescue
					say "FAILED!"
				end
			end

			if user_contact_form.old_marketplace_image.present? && !user_contact_form.marketplace_image.attached?
				begin
					say "Processing marketplace image (UserContactForm id #{user_contact_form.id}): #{user_contact_form.old_marketplace_image.url.inspect}"
					user_contact_form.marketplace_image.attach(io: open(user_contact_form.old_marketplace_image.url), filename: user_contact_form.old_marketplace_image.filename.split("/").last)
					say "COPIED"
					user_contact_form.remove_old_marketplace_image!
					say "DELETED"
					user_contact_form.save
					say "SAVED"
				rescue
					say "FAILED!"
				end
			end

			if user_contact_form.old_logo_image.present? && !user_contact_form.logo_image.attached?
				begin
					say "Processing logo image (UserContactForm id #{user_contact_form.id}): #{user_contact_form.old_logo_image.url.inspect}"
					user_contact_form.logo_image.attach(io: open(user_contact_form.old_logo_image.url), filename: user_contact_form.old_logo_image.filename.split("/").last)
					say "COPIED"
					user_contact_form.remove_old_logo_image!
					say "DELETED"
					user_contact_form.save
					say "SAVED"
				rescue
					say "FAILED!"
				end
			end
		end

		# remove_column :user_contact_forms, :old_background_image
		# remove_column :user_contact_forms, :old_marketplace_image
		# remove_column :user_contact_forms, :old_logo_image
	end

	def down
		rename_column  :user_contact_forms, :old_background_image, :background_image
		rename_column  :user_contact_forms, :old_marketplace_image, :marketplace_image
		rename_column  :user_contact_forms, :old_logo_image,   :logo_image

    change_column  :user_contact_forms, :price,            :integer,           null: false,        default: 0
	end
end
