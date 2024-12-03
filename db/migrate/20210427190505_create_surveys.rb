class CreateSurveys < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Surveys table...' do
      create_table :surveys, if_not_exists: true do |t|
        t.references :client,            foreign_key: true,                      index: true
        t.string     :name,              default: '',        null: false,        index: true
        t.string     :survey_key,        default: '',        null: false,        index: true
        t.string     :share_code,        default: '',        null: false,        index: true
        t.integer    :hits,              default: 0,         null: false
        t.jsonb      :data,              default: {},        null: false

        t.timestamps
      end
    end

    say_with_time 'Creating SurveyScreens table...' do
      create_table :survey_screens, if_not_exists: true do |t|
        t.references :survey,            foreign_key: true,                      index: true
        t.string     :name,              default: '',        null: false,        index: true
        t.string     :screen_type,       default: '',        null: false
        t.string     :screen_key,        default: '',        null: false,        index: true
        t.integer    :hits,              default: 0,         null: false
        t.jsonb      :data,              default: {},        null: false

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
