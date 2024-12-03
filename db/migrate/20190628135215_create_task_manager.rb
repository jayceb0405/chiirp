class CreateTaskManager < ActiveRecord::Migration[5.2]
  def up
    create_table   :tasks do |t|
      t.references :client,  foreign_key: {on_delete: :cascade}
      t.references :user
      t.references :contact
      t.string     :name,              null: false,        default: "",        index: :true
      t.text       :description,       null: false,        default: ""
      t.datetime   :date_due,          null: false
      t.datetime   :date_completed,    null: false

      t.timestamps
    end
  end

  def down
  	drop_table     :tasks
  end
end
