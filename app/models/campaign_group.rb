# frozen_string_literal: true

# app/models/campaign_group.rb
class CampaignGroup < ApplicationRecord
  has_one_attached :marketplace_image

  belongs_to :client
  belongs_to :client_attachment, optional: true

  has_one    :campaign_share_code, dependent: :destroy
  has_many   :campaigns,           dependent: nil
  has_many   :package_campaigns,   dependent: :delete_all

  store_accessor :data, :description

  validates :name, presence: true, length: { minimum: 1 }

  after_initialize :apply_new_record_data, if: :new_record?
  before_destroy   :before_destroy_process

  scope :by_tenant, ->(tenant = 'chiirp') {
    joins(:client)
      .where(clients: { tenant: })
  }

  # create a Campaign::ActiveRecord_AssociationRelation
  # campaign_group.campaigns
  def campaigns
    self.client.campaigns.where(campaign_group_id: self.id).order(:name)
  end

  # copy a CampaignGroup
  # campaign_group.copy(new_client_id: Integer)
  def copy(params)
    new_client_id      = params.dig(:new_client_id).to_i
    new_campaign_group = nil

    if new_client_id.positive?
      # new_client_id was received
      new_client = Client.find_by(id: new_client_id)

      if new_client
        # create new CampaignGroup
        new_campaign_group = self.dup
        new_campaign_group.name              = "Copy of #{new_campaign_group.name}" if new_client.campaign_groups.find_by(name: new_campaign_group.name)
        new_campaign_group.client_id         = new_client.id
        new_campaign_group.marketplace       = false
        new_campaign_group.marketplace_ok    = false
        new_campaign_group.price             = 0
        new_campaign_group.marketplace_image.attach(self.marketplace_image.blob) if self.marketplace_image.attached?

        if new_campaign_group.save
          # create a log of Campaign ids created
          new_campaign_ids = {}

          Campaign.where(campaign_group_id: self.id).find_each do |campaign|
            # copy Campaign
            if (new_campaign = campaign.copy(new_client_id: new_client.id, campaign_id_prefix: 'orig_'))
              # new Campaign was copied
              new_campaign_ids[campaign.id] = new_campaign.id
            else
              # new Campaign was NOT created

              Campaign.where(campaign_group_id: new_campaign_group.id).find_each do |c|
                c&.destroy
              end

              new_campaign_group.destroy
              new_campaign_group = nil
              break
            end
          end

          if new_campaign_group
            # new CampaignGroup was created successfully
            trackable_link_action_types = [100, 105, 170, 700]

            Campaign.where(campaign_group_id: new_campaign_group.id).find_each do |campaign|
              # scan through the new Campaigns and replace campaign_id references with new Campaign ids

              campaign.triggers.each do |trigger|
                # scan through each Trigger

                trigger.triggeractions.each do |triggeraction|
                  # scan through each Triggeraction

                  if triggeraction.action_type == 200
                    # start a Campaign

                    triggeraction.update(campaign_id: new_campaign_ids[triggeraction.campaign_id.sub('orig_', '').to_i].to_i) if triggeraction.campaign_id.to_s[0, 5] == 'orig_'
                  elsif triggeraction.action_type == 400
                    # stop a Campaign

                    triggeraction.update(campaign_id: new_campaign_ids[triggeraction.campaign_id.sub('orig_', '').to_i].to_s) if triggeraction.campaign_id.to_s[0, 5] == 'orig_'
                  elsif triggeraction.action_type == 605
                    # ClientCustomField action

                    if triggeraction.client_custom_field_id.positive? && (client_custom_field = campaign.client.client_custom_fields.find_by(id: triggeraction.client_custom_field_id))
                      # ClientCustomField is defined

                      client_custom_field.string_options_as_array.each do |_so|
                        # scan through each :string_option

                        triggeraction.response_range.each_value do |values|
                          values['campaign_id'] = new_campaign_ids[values.dig('campaign_id').sub('orig_', '').to_i].to_i if values.dig('campaign_id').to_s[0, 5] == 'orig_'
                        end
                      end

                      triggeraction.save
                    end

                  elsif trackable_link_action_types.include?(triggeraction.action_type) && self.client_id != new_campaign_group.client_id
                    # update any TrackableLinks if copying to a different Client

                    new_client.trackable_links.where(campaign_id: 0).find_each do |trackable_link|
                      if trackable_link.original_url.include?('#{orig_')
                        original_campaign_id = trackable_link.original_url[%r{#\{orig_.*\}}].gsub("\#{orig_", '').delete('}').to_i
                        trackable_link.update(
                          original_url: trackable_link.original_url[0, trackable_link.original_url.index("\#{orig_")],
                          campaign_id:  new_campaign_ids.include?(original_campaign_id) ? new_campaign_ids[original_campaign_id] : 0
                        )
                      end
                    end
                  end
                end
              end
            end
          end
        else
          # new Campaign was NOT saved
          new_campaign_group = nil
        end
      end
    end

    new_campaign_group
  end

  private

  def after_create_commit_actions
    super

    self.create_campaign_share_code.save
  end

  def apply_new_record_data
    # jsonb fields
    self.description ||= ''
  end

  def before_destroy_process
    # rubocop:disable Rails/SkipsModelValidations
    Campaign.where(campaign_group_id: self.id).update_all(campaign_group_id: 0)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
