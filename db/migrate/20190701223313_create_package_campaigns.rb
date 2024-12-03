class CreatePackageCampaigns < ActiveRecord::Migration[5.2]
  def up
    create_table :package_campaigns do |t|
      t.references :package,  foreign_key: {on_delete: :cascade}
      t.references :campaign
      t.references :campaign_group

      t.timestamps
    end
  end

  def down
  	drop_table :package_campaigns
  end
end
