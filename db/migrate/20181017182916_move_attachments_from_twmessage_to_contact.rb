class MoveAttachmentsFromTwmessageToContact < ActiveRecord::Migration[5.2]
  def up
    create_table :contact_attachments do |t|
      t.references :contact
      t.string :image

      t.timestamps
    end

    add_reference :twmessage_attachments, :contact_attachment

    TwmessageAttachment.all.each do |ta|
    	new_contact_attachment = ta.twmessage.contact.contact_attachments.new( image: ta.media_url )
	  	new_contact_attachment.save

	  	ta.update( contact_attachment_id: new_contact_attachment.id )
    end

    remove_column :twmessage_attachments, :media_url
  end

  def down
  	add_column :twmessage_attachments, :media_url, :string

  	TwmessageAttachment.all.each do |ta|
  		ta.update( media_url: ta.contact_attachment.image) unless ta.contact_attachment_id.nil?
  	end

    remove_reference :twmessage_attachments, :contact_attachment

		drop_table :contact_attachments
  end
end
