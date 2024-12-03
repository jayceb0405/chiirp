class ClientCustomFieldImageIsValid < ActiveRecord::Migration[5.2]
  def up
		add_column     :client_custom_fields, :image_is_valid, :boolean,           null: false,        default: false
  end

  def down
  	remove_column  :client_custom_fields, :image_is_valid
  end
end
