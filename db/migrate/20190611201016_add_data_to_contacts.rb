class AddDataToContacts < ActiveRecord::Migration[5.2]
  def up
  	remove_column :client_api_integrations, :data
  	add_column    :client_api_integrations, :data, :jsonb, null: false,   default: {}

    add_index     :client_api_integrations, :data, using: :gin

		add_column    :contacts, :data,         :jsonb,        null: false,   default: {}
    add_index     :contacts, :data, using: :gin
  end

  def down
    remove_column :contacts, :data

    remove_column :client_api_integrations, :data
    add_column    :client_api_integrations, :data, :text,  null: false,   default: {}.to_yaml
  end
end
