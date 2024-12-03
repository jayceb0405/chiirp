class AddTargetIndexToContactExtReferences < ActiveRecord::Migration[7.1]
  def change
    add_index :contact_ext_references, :target
  end
end
