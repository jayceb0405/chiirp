class ChangeUserContactFormFormattingToJsonb < ActiveRecord::Migration[5.2]
  def up
  	remove_column :user_contact_forms, :formatting
  	add_column :user_contact_forms, :formatting, :jsonb, default: {}, null: false
    add_index  :user_contact_forms, :formatting, using: :gin

    UserContactForm.all.each do |ucf|
    	ucf.submit_button_text  = "Submit"
    	ucf.submit_button_color = "#007bff"
      ucf.ok2text             = "1"
      ucf.ok2email            = "1"
      ucf.header_bg_color     = "#ffffff"
      ucf.body_bg_color       = "#ffffff"
      ucf.form_bg_color       = "#f8f9fa"
      ucf.header_text         = ""

    	ucf.save
    end
  end

  def down
  	change_column :user_contact_forms, :formatting, :text, default: "", null: false
  end
end
