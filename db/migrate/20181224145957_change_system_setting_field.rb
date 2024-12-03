class ChangeSystemSettingField < ActiveRecord::Migration[5.2]
  def up
  	change_column :system_settings, :setting_value, :string, default: "", null: false
  	add_column    :system_settings, :description, :string, default: "", null: false
  end

  def down
  	change_column :system_settings, :setting_value, "integer USING CAST(setting_value AS integer)", default: 0, null: false
  	remove_column :system_settings, :description
  end
end
