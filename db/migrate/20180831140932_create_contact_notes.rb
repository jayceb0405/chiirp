class CreateContactNotes < ActiveRecord::Migration[5.2]
  def up
    create_table :contact_notes do |t|
      t.references :contact, index: true
      t.references :user, index: true
      t.text :note

      t.timestamps
    end

    Contact.find_each do |c|
    	unless c.notes.nil? or c.notes.empty?
    		ContactNote.create!(contact_id: c.id, user_id: c.user_id, note: c.notes, created_at: c.created_at)
    	end
    end

    remove_column :contacts, :notes
  end

  def down
    add_column :contacts, :notes, :text

  	ContactNote.find_each do |c|
  		contact = Contact.find(c.contact_id)
  		contact.update(notes: (contact.notes || "") + "\n" + c.note)
  	end

  	drop_table :contact_notes
  end
end
