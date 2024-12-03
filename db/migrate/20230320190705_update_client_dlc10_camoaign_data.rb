class UpdateClientDlc10CamoaignData < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Update Clients::Dlc10::Campaign data...' do
      remove_column    :client_dlc10_campaigns, :next_qtr_date
      remove_column    :client_dlc10_campaigns, :qtr_charge

      Clients::Dlc10::Campaign.find_each do |campaign|
        campaign.update(
          mo_charge:    (campaign.mo_charge.to_d / 100) + 2.0,
          next_mo_date: campaign.next_mo_date + 1.month
        )
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
