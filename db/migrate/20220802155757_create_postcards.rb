class CreatePostcards < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Postcards...' do
      create_table :postcards do |t|
        t.references :client, foreign_key: true, index: true
        t.references :contact, foreign_key: true, index: true
        t.references :tag, foreign_key: true, index: true
        t.string     :target, default: '', null: false
        t.string     :card_id, default: '', null: false, index: true
        t.string     :card_name, default: '', null: false
        t.string     :result, default: '', null: false
        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
