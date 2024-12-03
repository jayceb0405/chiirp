class AddClientcustomFieldIdToOrgPosition < ActiveRecord::Migration[5.2]
  def up
  	add_reference  :org_positions,     :client_custom_field, index: true,      null: false,        default: 0
  end

  def down
  	remove_reference :org_positions,   :client_custom_field
  end
end
