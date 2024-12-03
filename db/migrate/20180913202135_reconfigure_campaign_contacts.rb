class ReconfigureCampaignContacts < ActiveRecord::Migration[5.2]
	def up
		create_table :contact_campaigns do |t|
			t.references :contact, index: true
			t.references :campaign, index: true
			t.boolean :completed, default: false

			t.timestamps
		end

		create_table :completed_triggeractions do |t|
			t.references :contact_campaign, index: true
			t.references :triggeraction, index: true

			t.timestamps
		end

		add_foreign_key :contact_campaigns, :contacts
		add_foreign_key :contact_campaigns, :campaigns
		add_foreign_key :completed_triggeractions, :contact_campaigns
		add_foreign_key :completed_triggeractions, :triggeractions

		Campaigncontact.distinct.pluck(:campaign_id, :contact_id).each do |campaign_id, contact_id|
			concam = ContactCampaign.create(contact_id: contact_id, campaign_id: campaign_id, completed: true)
			created_at = Time.current

			Campaigncontact.where(campaign_id: campaign_id, contact_id: contact_id).order(:created_at).each do |cc|
				triggeraction = CompletedTriggeraction.create(contact_campaign_id: concam.id, triggeraction_id: cc.triggeraction_id, created_at: cc.created_at)
				created_at = [created_at.utc, cc.created_at.utc].min
			end

			concam.created_at = created_at
			concam.save
		end

		drop_table :campaigncontacts
	end

	def down
    create_table :campaigncontacts do |t|
      t.references :contact, index: true
      t.references :campaign, index: true
      t.references :trigger, index: true, default: 0
    	t.references :triggeraction, index: true, default: 0
    	
      t.timestamps
    end

    CompletedTriggeraction.all.each do |ct|
    	Campaigncontact.create(
    		contact_id: ct.contact_campaign.contact_id,
    		campaign_id: ct.contact_campaign.campaign_id,
    		trigger_id: ct.triggeraction.trigger_id,
    		triggeraction_id: ct.triggeraction_id,
    		created_at: ct.created_at
    	)
    end

		drop_table :completed_triggeractions
		drop_table :contact_campaigns
	end
end
