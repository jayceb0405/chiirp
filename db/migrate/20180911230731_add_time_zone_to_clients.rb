class AddTimeZoneToClients < ActiveRecord::Migration[5.2]
  def up
    add_column :clients, :time_zone, :string, default: "UTC"
  end

  def down
    remove_column :clients, :time_zone
  end
end
