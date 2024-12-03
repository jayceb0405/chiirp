class AddTriggeractionRefToCampaigncontacts < ActiveRecord::Migration[5.2]
  def up
  	add_column :triggeractions, :sequence, :integer, default: 0
    add_reference :campaigncontacts, :triggeraction, index: true, default: 0
  end

  def down
  	remove_column :triggeractions, :sequence
    remove_reference :campaigncontacts, :triggeraction
  end
end
