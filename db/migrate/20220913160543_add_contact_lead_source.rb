class AddContactLeadSource < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Clients::LeadSource table...' do
      create_table :clients_lead_sources do |t|
        t.references :client, foreign_key: true, index: true
        t.string     :name, default: 'New Lead Source', null: false

        t.timestamps
      end
    end

    say_with_time 'Adding "lead_source" to Contacts table...' do
      add_reference :contacts, :lead_source, foreign_key: { to_table: :clients_lead_sources }
      add_column    :contacts, :lead_source_id_updated_at,  :datetime
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
