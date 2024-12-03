class ConvertCampaignGroup < ActiveRecord::Migration[6.0]
  def up
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Converting Campaign.campaign_group_id to remove nulls..." do
			Campaign.update_all( campaign_group_id: 0)
			change_column    :campaigns,     :campaign_group_id, :integer,           null: false,        references: :campaign_groups, index: true,        default: 0
		end

		say_with_time "Analyzing all Campaigns..." do
			add_column       :campaigns,     :analyzed,          :boolean,           null: false,        default: false

			# Campaign.reset_column_information

			# Campaign.all.find_each do |campaign|
			# 	campaign.update( analyzed: campaign.analyze!.empty? )
			# end
		end

		say_with_time "Populating Campaign.campaign_group_id with data from CampaignGroup..." do

			CampaignGroup.all.find_each do |campaign_group|
				Campaign.where( id: campaign_group.data["campaign_ids"] ).update_all( campaign_group_id: campaign_group.id )
			end

			CampaignGroup.all.find_each do |campaign_group|
				campaign_group.update( data: { "description" => campaign_group.data["description"] } )
			end
		end

		say_with_time "Updating Triggeractions that Stop Campaigns..." do

			Triggeraction.where( action_type: 400 ).find_each do |triggeraction|

				unless triggeraction.data.dig(:campaign_id).to_s.empty?

					case triggeraction.data.dig(:campaign_id).to_s
					when "0"
						triggeraction.data[:campaign_id] = "all_other"
					when "-1"
						triggeraction.data[:campaign_id] = "this"
					end

					triggeraction.save
				end
			end
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end

  def down
		ActiveRecord::Base.record_timestamps = false
		say "Turned off timestamps."

		say_with_time "Populating CampaignGroup.data[\"campaign_ids\"] with data from Campaign.campaign_group_id..." do

			CampaignGroup.all.find_each do |campaign_group|
				data = campaign_group.data
				data["campaign_ids"] = Campaign.where( campaign_group_id: campaign_group.id ).pluck(:id)
				campaign_group.update( data: data )
			end
		end

		say_with_time "Reversing Campaign.campaign_group_id to include nulls..." do
			change_column    :campaigns,     :campaign_group_id, :integer,           null: true,        references: :campaign_groups, index: true
			Campaign.update_all( campaign_group_id: nil)
		end

		say_with_time "Reversing Triggeractions that Stop Campaigns..." do

			Triggeraction.where( action_type: 400 ).find_each do |triggeraction|

				unless triggeraction.data.dig(:campaign_id).to_s.empty?

					case triggeraction.data.dig(:campaign_id).to_s
					when "all_other"
						triggeraction.data[:campaign_id] = "0"
					when "this"
						triggeraction.data[:campaign_id] = "-1"
					end

					triggeraction.save
				end
			end
		end

		say_with_time "Removing Analyzed column from Campaigns..." do
			remove_column    :campaigns,     :analyzed
		end

		ActiveRecord::Base.record_timestamps = true
		say "Turned on timestamps."
  end
end
