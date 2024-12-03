class CreateEmailTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :email_templates do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name
      t.string :subject
      t.text :content

      t.timestamps

      t.index [:name, :client_id], unique: true
    end
  end
end
