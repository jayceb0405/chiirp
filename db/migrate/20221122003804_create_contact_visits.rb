class CreateContactVisits < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ContactRequests table...' do
      create_table :contact_requests do |t|
        t.references    :contact, foreign_key: true, index: true
        t.string        :ext_source, default: '', null: false
        t.string        :ext_id, default: '', null: false, index: true
        t.string        :status, default: '', null: false
        t.datetime      :start_at
        t.datetime      :end_at

        t.timestamps
      end
    end

    say_with_time 'Creating ContactVisits table...' do
      create_table :contact_visits do |t|
        t.references    :contact, foreign_key: true, index: true
        t.references    :job, foreign_key: {to_table: 'contact_jobs'}, index: true
        t.string        :ext_source, default: '', null: false
        t.string        :ext_id, default: '', null: false, index: true
        t.string        :status, default: '', null: false
        t.datetime      :start_at
        t.datetime      :end_at
        t.string        :ext_tech_id, default: '', null: false

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
