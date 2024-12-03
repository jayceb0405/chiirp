class CreateContactFbPages < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ContactFbPages table...' do
      create_table :contact_fb_pages do |t|
        t.references    :contact, foreign_key: true, index: true
        t.string        :page_id,                          default: '',             null: false
        t.string        :page_scoped_id,                   default: '',             null: false

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
