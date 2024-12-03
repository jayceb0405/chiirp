class CreateIntegrationCardxTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_transactions do |t|
      t.belongs_to :client, foreign_key: { on_delete: :nullify }
      t.belongs_to :contact_jobs, foreign_key: { on_delete: :nullify }
      
      t.string :target, null: false
      t.string :payment_type, null: false

      t.decimal :amount_total, default: "0.0", null: false
      t.decimal :amount_requested, default: "0.0", null: false
      t.decimal :amount_fees, default: "0.0", null: false

      t.datetime :transacted_at, null: false

      t.timestamps

      t.index :target
      t.index :transacted_at
    end
  end
end
