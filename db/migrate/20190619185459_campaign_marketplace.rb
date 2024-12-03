class CampaignMarketplace < ActiveRecord::Migration[5.2]
	def up
		create_table :campaign_groups do |t|
			t.string                         :name,                                  null: false,        default: ""
			t.boolean                        :marketplace,                           null: false,        default: false
			t.boolean                        :marketplace_ok,                        null: false,        default: false
			t.integer                        :price,                                 null: false,        default: 0
			t.jsonb                          :data,                                  null: false,        default: {}

			t.timestamps
		end

		create_table :campaign_share_codes do |t|
			t.references :campaign,          foreign_key: {on_delete: :cascade}
			t.references :campaign_group,    foreign_key: {on_delete: :cascade}
			t.string                         :share_code,                            null: false,        default: "",        index: true

			t.timestamps
		end

		Campaign.all.each do |campaign|
			campaign.create_campaign_share_code(share_code: campaign.share_code)
			campaign.save
		end

		remove_column  :campaigns,         :share_code

		add_reference  :campaigns,         :campaign_group
		add_column     :campaigns,         :marketplace,       :boolean,           null: false,        default: false
		add_column     :campaigns,         :marketplace_ok,    :boolean,           null: false,        default: false
		add_column     :campaigns,         :price,             :integer,           null: false,        default: 0
		add_column     :campaigns,         :data,              :jsonb,             null: false,        default: {}
	end

	def down
		# add_column     :campaigns,         :share_code,                            null: false,        default: "",        index: true

		CampaignShareCode.all.each do |campaign_share_code|
			campaign_share_code.campaign.update(share_code: campaign_share_code.share_code)
		end

		remove_reference  :campaigns,         :campaign_group
		remove_column     :campaigns,         :marketplace
		remove_column     :campaigns,         :marketplace_ok
		remove_column     :campaigns,         :price
		remove_column     :campaigns,         :data
		drop_table        :campaign_share_codes
		drop_table        :campaign_groups
	end
end
