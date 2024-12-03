class AddFieldsToClientDlc10Brands < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding new fields to Clients::Dlc10::Brands...' do
      add_column :client_dlc10_brands, :submitted_at, :datetime
      add_column :client_dlc10_brands, :resubmitted_at, :datetime
      add_column :client_dlc10_brands, :verified_at, :datetime

      Clients::Dlc10::Brand.find_each do |brand|
        brand.submitted_at = brand.created_at if brand.tcr_brand_id.present?
        brand.verified_at  = brand.updated_at if brand.tcr_brand_id.present?
        brand.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
