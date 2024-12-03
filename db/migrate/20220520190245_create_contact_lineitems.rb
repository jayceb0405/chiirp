class CreateContactLineitems < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating Contacts::Lineitems...' do
      create_table :contact_lineitems do |t|
        t.references :lineitemable, polymorphic: true
        t.string     :name,                                default: '',        null: false
        t.decimal    :total,                               default: 0,         null: false
        t.string     :ext_id,                              default: '',        null: false

        t.timestamps
      end

      add_index :contact_lineitems, [:lineitemable_type, :lineitemable_id], name: 'index_lineitems_on_lineitemable_type_and_lineitemable_id'
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing Contacts::Lineitems...' do
      drop_table :contact_lineitems
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
