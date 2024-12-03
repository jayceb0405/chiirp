class AddPaymentsReceivedToJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :contact_jobs, :payments_received, :decimal, default: '0.0', null: false
  end
end
