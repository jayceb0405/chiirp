class AddVersionToEmailTemplate < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "version" to EmailTemplates table...' do
      add_column :email_templates, :version, :integer, default: 2, null: false
    end

    say_with_time 'Updating "version" of existing EmailTemplates records to 1...' do
      EmailTemplate.where(html: nil).update_all(version: 1)
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'

  end
end
