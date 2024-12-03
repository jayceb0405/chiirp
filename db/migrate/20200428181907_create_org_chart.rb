class CreateOrgChart < ActiveRecord::Migration[5.2]
  def up
    create_table :org_positions do |t|
			t.references :client,            foreign_key: {on_delete: :cascade}
      t.string     :title,             default: "",        null: false
      t.bigint     :level,             default: 0,         null: false,        index: true

      t.timestamps
   end

    create_table :org_users do |t|
			t.references :client,                                                    foreign_key: {on_delete: :cascade}
			t.references :user,              default: 0,         null: false,        on_delete: :cascade
      t.bigint     :org_group,         default: 0,         null: false
			t.references :org_position,      default: 0,         null: false,        on_delete: :cascade
      t.string     :firstname,         default: "",        null: false
      t.string     :lastname,          default: "",        null: false
      t.string     :phone,             default: "",        null: false

      t.timestamps
    end
  end

  def down
  	drop_table     :org_users
  	drop_table     :org_positions
  end
end
