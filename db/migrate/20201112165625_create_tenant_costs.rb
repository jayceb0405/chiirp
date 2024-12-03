class CreateTenantCosts < ActiveRecord::Migration[6.0]
  def change
    create_table :tenant_costs do |t|
      t.string     :tenant,            default: '',        null: false,        index: false
      t.integer    :month,             default: 0,         null: false,        index: false
      t.integer    :year,              default: 0,         null: false,        index: false
      t.string     :cost_key,          default: '',        null: false,        index: false
      t.decimal    :cost_value,        default: 0,         null: false,        index: false

      t.timestamps null: false
    end

    add_index(:tenant_costs, [:tenant, :month, :year, :cost_key])
  end
end
