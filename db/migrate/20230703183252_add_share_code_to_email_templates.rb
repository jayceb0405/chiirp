class AddShareCodeToEmailTemplates < ActiveRecord::Migration[7.0]
  def change
    change_table :email_templates do |t|
      t.string "share_code", default: "", null: false
      # t.index :share_code, unique: true
    end
  end
end
