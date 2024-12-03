class CompletedTriggeractionIndex < ActiveRecord::Migration[6.1]
  def change
    add_index      :completed_triggeractions,    :triggeraction_id
  end
end
