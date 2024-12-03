class MergeClientDlc10RegistrationsIntoClientDlc10Campaigns < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding new fields to Clients::Dlc10::Campaign...' do
      add_column    :client_dlc10_campaigns, :tcr_campaign_id, :string
      add_column    :client_dlc10_campaigns, :phone_vendor, :string
      add_column    :client_dlc10_campaigns, :shared_at, :datetime
      add_column    :client_dlc10_campaigns, :accepted_at, :datetime
      add_column    :client_dlc10_campaigns, :dca_completed_at, :datetime

      Clients::Dlc10::Campaign.find_each do |campaign|
        registration = Clients::Dlc10::Registration.find_by(dlc10_campaign_id: campaign.id, phone_vendor: 'bandwidth')
        campaign.update(
          tcr_campaign_id:  registration&.tcr_campaign_id,
          phone_vendor:     'bandwidth',
          shared_at:        registration&.shared_at,
          accepted_at:      registration&.approved_at,
          dca_completed_at: registration&.dca_completed_at,
        )
      end
    end

    say_with_time 'Deleting Clients::Dlc10::Registration...' do
      drop_table :client_dlc10_registrations
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
