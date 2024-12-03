class CreateClientDlc10CampaignRegistrations < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Renaming Clients::Dlc10::Brand table...' do
      rename_table :clients_dlc10_brands, :client_dlc10_brands
    end

    say_with_time 'Renaming Clients::Dlc10::Campaign table...' do
      rename_table :clients_dlc10_campaigns, :client_dlc10_campaigns
    end

    say_with_time 'Creating Clients::Dlc10::Registration table...' do

      create_table :client_dlc10_registrations do |t|
        t.references :dlc10_campaign, foreign_key: {to_table: 'client_dlc10_campaigns'}, index: true
        t.string :tcr_campaign_id
        t.string :phone_vendor
        t.datetime :shared_at
        t.datetime :approved_at

        t.timestamps
      end
    end

    say_with_time 'Migrating Clients::Dlc10::Campaign table (tcr_campaign_id, shared_at)...' do
      Clients::Dlc10::Campaign.find_each do |dlc10_campaign|
        dlc10_campaign.registrations.create(tcr_campaign_id: dlc10_campaign.tcr_campaign_id, phone_vendor: dlc10_campaign.brand.client.phone_vendor, shared_at: dlc10_campaign.shared_at, approved_at: dlc10_campaign.shared_at, created_at: Time.current, updated_at: Time.current)
      end

      add_column    :client_dlc10_campaigns, :help_message, :text, default: '', null: false
      add_column    :client_dlc10_campaigns, :message_flow, :text, default: '', null: false
      add_column    :client_dlc10_campaigns, :optout_message, :text, default: '', null: false
      remove_column :client_dlc10_campaigns, :shared_at
      remove_column :client_dlc10_campaigns, :tcr_campaign_id
    end

    say_with_time 'Modifying Twnumbers table (dlc10_campaign_id)...' do
      rename_column :twnumbers, :dlc10_campaign_id, :old_dlc10_campaign_id
      add_reference :twnumbers, :dlc10_campaign, to_table: 'client_dlc10_campaigns', index: true

      Twnumber.find_each do |twnumber|
        twnumber.update(dlc10_campaign_id: twnumber.old_dlc10_campaign_id) if twnumber.old_dlc10_campaign_id.positive?
      end

      remove_column :twnumbers, :old_dlc10_campaign_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating Clients::Dlc10::Campaign table (tcr_campaign_id, shared_at)...' do
      add_column    :client_dlc10_campaigns, :shared_at, :datetime
      add_column    :client_dlc10_campaigns, :tcr_campaign_id, :string
      remove_column :client_dlc10_campaigns, :help_message
      remove_column :client_dlc10_campaigns, :message_flow
      remove_column :client_dlc10_campaigns, :optout_message

      Clients::Dlc10::Registration.find_each do |dlc10_registration|
        dlc10_registration.campaign.update(tcr_campaign_id: dlc10_registration.tcr_campaign_id, shared_at: dlc10_registration.shared_at)
      end
    end

    say_with_time 'Renaming Clients::Dlc10::Brand table...' do
      rename_table :client_dlc10_brands, :clients_dlc10_brands
    end

    say_with_time 'Renaming Clients::Dlc10::Campaign table...' do
      rename_table :client_dlc10_campaigns, :clients_dlc10_campaigns
    end

    say_with_time 'Deleting Clients::Dlc10::Registration table...' do
      drop_table :client_dlc10_registrations
    end

    say_with_time 'Modifying Twnumbers table (dlc10_campaign_id)...' do
      rename_column :twnumbers, :dlc10_campaign_id, :old_dlc10_campaign_id
      add_reference :twnumbers, :dlc10_campaign, default: 0, null: false, to_table: 'clients_dlc10_campaigns', index: true

      Twnumber.find_each do |twnumber|
        twnumber.update(dlc10_campaign_id: twnumber.old_dlc10_campaign_id.to_i)
      end

      remove_column :twnumbers, :old_dlc10_campaign_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
