class AddCancelAtToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column     :tasks,             :cancel_after,      :integer,           null: false,        default: 0
  end
end
