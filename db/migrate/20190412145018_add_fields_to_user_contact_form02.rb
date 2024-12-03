class AddFieldsToUserContactForm02 < ActiveRecord::Migration[5.2]
  def up
  	add_column :user_contact_forms, :form_name,  :string, default: "", null: false
		add_column :user_contact_forms, :share_code, :string, default: "", null: false
		add_index  :user_contact_forms, :share_code

  	UserContactForm.all.each do |ucf|
	  	ucf.tag_line      = ucf.header_text || ""
	  	ucf.share_code    = random_code(20) until UserContactForm.find_by_share_code(ucf.share_code).nil?
    	ucf.ok2text_text  = "May We Send Text Messages?"
    	ucf.ok2email_text = "May We Send Email Messages?"
    	ucf.youtube_video = ""
    	ucf.form_name     = ucf.title
			ucf.save
  	end
  end

  def down
  	remove_column :user_contact_forms, :form_name
  	remove_column :user_contact_forms, :share_code

  	UserContactForm.all.each do |ucf|
	  	ucf.update(header_text: ucf.tag_line)
	  end
  end

  def random_code(len = 6)
		chars = ['0'..'9', 'A'..'Z', 'a'..'z'].map { |range| range.to_a }.flatten
		len.times.map{ chars.sample }.join
	end
end
