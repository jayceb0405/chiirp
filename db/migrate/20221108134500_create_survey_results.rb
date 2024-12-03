class CreateSurveyResults < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating SurveyResults table...' do
      create_table :survey_results do |t|
        t.references    :survey, foreign_key: true, index: true
        t.references    :contact, null: true, default: nil, foreign_key: true, index: true
        t.jsonb         :data, default: {}, null: false

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
