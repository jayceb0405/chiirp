class CreateContactSubscription < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ContactSubscriptions table...' do
      create_table :contact_subscriptions do |t|
        t.references :contact, foreign_key: true, index: true
        t.string     :ext_source, default: '', null: false
        t.string     :ext_id, default: '', null: false, index: true
        t.string     :customer_id, default: '', null: false
        t.string     :customer_number, default: '', null: true
        t.string     :firstname, default: '', null: true
        t.string     :lastname, default: '', null: true
        t.string     :companyname, default: '', null: true
        t.string     :address_01, default: '', null: true
        t.string     :address_02, default: '', null: true
        t.string     :city, default: '', null: true
        t.string     :state, default: '', null: true
        t.string     :postal_code, default: '', null: true
        t.string     :country, default: '', null: true
        t.decimal    :total, default: 0.0, null: false
        t.decimal    :total_due, default: 0.0, null: false
        t.string     :description, default: '', null: true
        t.datetime   :added_at, null: true
        t.datetime   :cancelled_at, null: true

        t.timestamps
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
