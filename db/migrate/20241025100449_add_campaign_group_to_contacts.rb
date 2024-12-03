class AddCampaignGroupToContacts < ActiveRecord::Migration[7.2]
  def change
    add_reference :contacts, :campaign_group, foreign_key: true, null: true
  end
end
