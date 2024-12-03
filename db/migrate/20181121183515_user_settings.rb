class UserSettings < ActiveRecord::Migration[5.2]
  def up
    create_table :user_settings do |t|
      t.references :user, foreign_key: true
      t.string     :controller_action, default: ""
      t.string     :name, default: ""
      t.string     :current, default: "0"
			t.text       :data

      t.timestamps
    end
  end

  def down
    drop_table :user_settings
  end
end
