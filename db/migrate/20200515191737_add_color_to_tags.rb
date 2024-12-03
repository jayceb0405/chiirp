class AddColorToTags < ActiveRecord::Migration[5.2]
  def up
		add_column     :tags,              :color,             :string,            null: false,        default: ""
  end

  def down
  	remove_column  :tags,              :color
  end
end
