class AddClientContact < ActiveRecord::Migration[5.2]
  def up
  	add_reference  :clients,           :contact,           index: true,        null: false,        default: 0

  	Contact.where(phone: Client.all.collect { |c| c.phone }).each do |contact|

  		if client = Client.find_by( phone: contact.phone, contact_id: 0 )
  			client.update( contact_id: contact.id )
  		end
  	end
  end

  def down
  	remove_reference  :clients,        :contact
  end
end
