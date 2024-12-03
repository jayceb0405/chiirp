class CreateContactInvoice < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ContactRawPosts table...' do
      create_table :contact_raw_posts do |t|
        t.references    :contact, foreign_key: true, index: true
        t.string        :ext_source,                       default: '',        null: false
        t.string        :ext_id,                           default: '',        null: false,        index: true
        t.jsonb         :data,                             default: {},        null: false

        t.timestamps
      end
    end

    say_with_time 'Creating ContactEstimates table...' do
      create_table :contact_estimates do |t|
        t.references    :contact, foreign_key: true, index: true
        t.string        :estimate_number,                  default: '',        null: false,        index: true
        t.string        :status,                           default: '',        null: false
        t.string        :address_01,                       default: '',        null: false
        t.string        :address_02,                       default: '',        null: false
        t.string        :city,                             default: '',        null: false
        t.string        :state,                            default: '',        null: false
        t.string        :postal_code,                      default: '',        null: false
        t.string        :country,                          default: '',        null: false
        t.datetime      :scheduled_start_at
        t.datetime      :scheduled_end_at
        t.integer       :scheduled_arrival_window,         default: 0,         null: false
        t.datetime      :actual_started_at
        t.datetime      :actual_completed_at
        t.datetime      :actual_on_my_way_at
        t.string        :technician_id,                    default: '',        null: false
        t.text          :notes,                            default: '',        null: false
        t.string        :ext_source,                       default: '',        null: false
        t.string        :ext_id,                           default: '',        null: false,        index: true

        t.timestamps
      end
    end

    say_with_time 'Creating ContactEstimateOptions table...' do
      create_table :contact_estimate_options do |t|
        t.references    :estimate, foreign_key: {to_table: 'contact_estimates'}, index: true
        t.string        :name,                             default: '',        null: false
        t.string        :status,                           default: '',        null: false
        t.string        :option_number,                    default: '',        null: false,        index: true
        t.decimal       :total_amount,                     default: 0,         null: false
        t.text          :notes,                            default: '',        null: false
        t.text          :message,                          default: '',        null: false
        t.string        :ext_source,                       default: '',        null: false
        t.string        :ext_id,                           default: '',        null: false,        index: true

        t.timestamps
      end
    end

    say_with_time 'Creating ContactJobs table...' do
      create_table :contact_jobs do |t|
        t.references    :contact, foreign_key: true, index: true
        t.references    :estimate, foreign_key: {to_table: 'contact_estimates'}, index: true
        t.string        :status,                           default: '',        null: false
        t.text          :description,                      default: '',        null: false
        t.string        :address_01,                       default: '',        null: false
        t.string        :address_02,                       default: '',        null: false
        t.string        :city,                             default: '',        null: false
        t.string        :state,                            default: '',        null: false
        t.string        :postal_code,                      default: '',        null: false
        t.string        :country,                          default: '',        null: false
        t.datetime      :scheduled_start_at
        t.datetime      :scheduled_end_at
        t.integer       :scheduled_arrival_window,         default: 0,         null: false
        t.datetime      :actual_started_at
        t.datetime      :actual_completed_at
        t.datetime      :actual_on_my_way_at
        t.decimal       :total_amount,                     default: 0,         null: false
        t.decimal       :outstanding_balance,              default: 0,         null: false
        t.string        :technician_id,                    default: '',        null: false
        t.text          :notes,                            default: '',        null: false
        t.string        :invoice_number,                   default: '',        null: false,        index: true
        t.datetime      :invoice_date
        t.string        :ext_source,                       default: '',        null: false
        t.string        :ext_id,                           default: '',        null: false,        index: true

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
