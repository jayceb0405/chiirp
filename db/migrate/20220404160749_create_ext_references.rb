class CreateExtReferences < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ContactExtReferences table...' do
      create_table :contact_ext_references do |t|
        t.references    :contact, foreign_key: true, index: true
        t.string        :target,                           default: '',        null: false
        t.string        :ext_id,                           default: '',        null: false

        t.timestamps
      end
    end

    say_with_time 'Adding Company Name to Contact table...' do
      add_column :contacts, :companyname, :string, null: false, default: ''
    end

    # process this conversion of Contact.ext_ref_id -> Contacts::ExtReference in Rails console
    # Contact.migrate_ext_ref_ids
    
    say 'Turned on timestamps.'
  end
end
