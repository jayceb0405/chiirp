class AddDefaultToUserSettings < ActiveRecord::Migration[5.2]
  def up
  	change_column  :user_settings,     :controller_action, :string,            null: false,        default: ""
  	change_column  :user_settings,     :name,              :string,            null: false,        default: ""
  	change_column  :user_settings,     :data,              :text,              null: false,        default: {}.to_yaml

  	add_column     :user_settings,     :current_new,       :integer,           null: false,        default: 0

  	UserSetting.update_all( "current_new = current::integer" )

  	remove_column  :user_settings,     :current
  	rename_column  :user_settings,     :current_new,       :current
  end

  def down
  	change_column  :user_settings,     :controller_action, :string,            null: true,         default: ""
  	change_column  :user_settings,     :name,              :string,            null: true,         default: ""
  	change_column  :user_settings,     :current,           :string,            null: true,         default: "0"
  	change_column  :user_settings,     :data,              :text,              null: true,         default: nil
  end
end
