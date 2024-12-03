class ConvertMarketplacePriceToDecimal < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    change_column  :campaigns,         :price,             :decimal,           default: 0,         null: false

    say_with_time 'Converting Campaigns...' do
      Campaign.find_each do |campaign|
        campaign.update(price: campaign.price.to_d/100)
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
