class AddOnetimetoPackagesandPages < ActiveRecord::Migration[7.1]
  def change
    change_table :packages do |t|
      t.boolean :onetime, default: false, null: false
      t.date :expired_on
    end
    change_table :package_pages do |t|
      t.boolean :onetime, default: false, null: false
      t.date :expired_on
    end
    change_table :clients do |t|
      t.belongs_to :package, foreign_key: true
      t.belongs_to :package_page, foreign_key: true
    end
  end
end
