class UpdateEmailTemplates < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "html, css" to EmailTemplates table...' do
      add_column :email_templates, :html, :text
      add_column :email_templates, :css, :text
      add_column :email_templates, :template, :boolean, null: false, default: false
      add_column :email_templates, :category, :string
      change_column_null :email_templates, :client_id, true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
