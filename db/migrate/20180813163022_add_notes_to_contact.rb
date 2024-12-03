class AddNotesToContact < ActiveRecord::Migration[5.2]
  def self.up
    add_column :contacts, :notes, :text
  end

  def self.down
    remove_column :contacts, :notes
  end
end
