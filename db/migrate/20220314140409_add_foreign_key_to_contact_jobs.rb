class AddForeignKeyToContactJobs < ActiveRecord::Migration[7.0]
  def up
    remove_foreign_key :contact_jobs, :contact_estimates

    add_foreign_key :contact_jobs, :contact_estimates, column: 'estimate_id', on_delete: :cascade
  end

  def down
    remove_foreign_key :contact_jobs, :contact_estimates

    add_foreign_key :contact_jobs, :contact_estimates
  end
end
