class CreatePartnerTable < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Partner table...' do
      create_table :partners do |t|
        t.string  :company_name
        t.string  :contact_name
        t.string  :contact_phone
        t.string  :contact_email
        t.decimal :commission, default: 0, null: false
        t.text    :notes

        t.timestamps
      end
    end

    say_with_time 'Updating Client table...' do
      add_reference :clients, :partner, foreign_key: { to_table: :partners }, index: true
    end

    say_with_time 'Updating Package table...' do
      add_reference :packages, :partner, foreign_key: { to_table: :partners }, index: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
