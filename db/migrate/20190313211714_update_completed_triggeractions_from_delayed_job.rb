class UpdateCompletedTriggeractionsFromDelayedJob < ActiveRecord::Migration[5.2]
  def up
    add_reference :delayed_jobs, :contact_campaign, null: false, default: 0, index: true

  	DelayedJob.all.each do |dj|
			if dj.triggeraction_id > 0
				# message is part of a Campaign

				if dj.triggeraction && dj.triggeraction.trigger && dj.triggeraction.trigger.campaign
					# add ContactCampaign id
					incomplete_contact_campaign = dj.triggeraction.trigger.campaign.contact_campaigns.where(contact_id: dj.contact_id, completed: false).first

					if incomplete_contact_campaign
						dj.update(contact_campaign_id: incomplete_contact_campaign.id)
						
						# flag Triggeraction as complete
						dj.contact.triggeraction_complete( triggeraction_id: dj.triggeraction_id, contact_campaign_id: incomplete_contact_campaign.id )
					end

				end
			end
  	end
  end

  def down
  	remove_reference :delayed_jobs, :contact_campaign
  end
end
