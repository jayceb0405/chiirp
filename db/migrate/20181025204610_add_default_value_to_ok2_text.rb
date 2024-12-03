class AddDefaultValueToOk2Text < ActiveRecord::Migration[5.2]
  def up
  	change_column :contacts, :ok2text, :string, default: "0"
  end

  def down
  	change_column :contacts, :ok2text, :string, default: nil
  end
end
