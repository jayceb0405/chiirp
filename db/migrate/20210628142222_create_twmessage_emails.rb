class CreateTwmessageEmails < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating TwmessageEmails table...' do

      create_table :twmessage_emails do |t|
        t.references :twmessage,         foreign_key: true,                      index: true
        t.string     :text_body,         default: '',        null: false
        t.string     :html_body,         default: '',        null: false
        t.string     :headers,           default: '',        null: false
        t.jsonb      :data,              default: {},        null: false

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
