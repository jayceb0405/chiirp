class AddGroupUuidToDelayedJob < ActiveRecord::Migration[7.1]
  def change
    add_column :delayed_jobs, :group_uuid, :string, null: true
    add_index  :delayed_jobs, :group_uuid
  end
end
