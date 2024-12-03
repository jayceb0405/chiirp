class AddIndexToEmailTemplates < ActiveRecord::Migration[7.0]
  def change
    change_table :email_templates do |t|
      t.index :share_code, unique: true
    end
  end
end
