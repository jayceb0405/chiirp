class AddCampaignIdToTag < ActiveRecord::Migration[5.2]
  def up
  	add_reference  :tags,              :campaign,           index: true,        null: false,        default: 0
  	add_reference  :tags,              :group,              index: true,        null: false,        default: 0
  	add_reference  :tags,              :tag,                index: true,        null: false,        default: 0
  end

  def down
  	remove_reference  :tags,           :campaign
  	remove_reference  :tags,           :group
  	remove_reference  :tags,           :tag
  end
end
