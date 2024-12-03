class AdjustTagForeignKeys < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :trackable_links, :tags
    add_foreign_key :trackable_links, :tags, on_delete: :cascade
  end

  def down
    remove_foreign_key :trackable_links, :tags
    add_foreign_key :trackable_links, :tags
  end
end
