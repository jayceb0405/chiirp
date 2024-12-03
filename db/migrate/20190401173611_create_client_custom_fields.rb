class CreateClientCustomFields < ActiveRecord::Migration[5.2]
  def up
    create_table :client_custom_fields do |t|
      t.references :client, foreign_key: true
      t.string     :var_name,        default: "",   null: false
      t.string     :var_var,         default: "",   null: false, index: true
      t.string     :var_type,        default: "",   null: false
      t.string     :var_options,     default: "",   null: false
      t.string     :var_placeholder, default: "",   null: false
      t.boolean    :var_important,   default: true, null: false
    end

    create_table :contact_custom_fields do |t|
      t.references :contact, foreign_key: true
      t.references :client_custom_field, foreign_key: true
      t.string     :var_value,       default: "",   null: false
    end
  end

  def down
    drop_table :contact_custom_fields
  	drop_table :client_custom_fields
  end
end
