class RemoveTemplatefromEmailTemplate < ActiveRecord::Migration[7.0]
  def change
    remove_column :email_templates, :template
  end
end
