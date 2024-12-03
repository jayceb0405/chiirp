class AddSuportEmailClientDlc10Brand < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding/updating fields in Clients::Dlc10::Brand...' do
      add_column    :client_dlc10_brands, :support_email, :string, default: nil, null: true
      change_column :client_dlc10_brands, :website, :string, default: nil, null: true
      remove_column :client_dlc10_campaigns, :help_message
      remove_column :client_dlc10_campaigns, :optout_message
      remove_column :client_dlc10_campaigns, :subscriber_help
      remove_column :client_dlc10_campaigns, :subscriber_optin
      remove_column :client_dlc10_campaigns, :subscriber_optout

      Clients::Dlc10::Brand.where(website: '').update_all(website: nil)
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding/updating fields in Clients::Dlc10::Brand...' do
      remove_column :client_dlc10_brands, :support_email
      add_column    :client_dlc10_campaigns, :help_message, :text, default: '', null: false
      add_column    :client_dlc10_campaigns, :optout_message, :text, default: '', null: false
      add_column    :client_dlc10_campaigns, :subscriber_help, :boolean, default: true, null: false
      add_column    :client_dlc10_campaigns, :subscriber_optin, :boolean, default: true, null: false
      add_column    :client_dlc10_campaigns, :subscriber_optout, :boolean, default: true, null: false

      Clients::Dlc10::Brand.where(website: nil).update_all(website: '')

      change_column :client_dlc10_brands, :website, :string, default: '', null: false
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
