class CreateGoogleReviews < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Reviews...' do
      create_table :reviews do |t|
        t.references :client, foreign_key: true, index: true
        t.references :contact, foreign_key: true, index: true
        t.string     :name, default: '', null: false
        t.string     :review_id, default: '', null: false, index: true
        t.integer    :star_rating, default: 5, null: false
        t.string     :comment, default: '', null: false
        t.string     :reply, default: '', null: false
        t.datetime   :replied_at
        t.string     :target, default: '', null: false
        t.datetime   :target_created_at
        t.datetime   :target_updated_at

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
