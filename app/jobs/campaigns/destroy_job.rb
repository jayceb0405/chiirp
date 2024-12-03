# frozen_string_literal: true

# app/jobs/campaigns/destroy_job.rb
module Campaigns
  class DestroyJob < ApplicationJob
    # remove all references to a destroyed Campaign
    # Campaigns::DestroyJob.perform_now()
    # Campaigns::DestroyJob.set(wait_until: 1.day.from_now).perform_later()
    # Campaigns::DestroyJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'campaign_destroy').to_s
    end

    # perform the ActiveJob
    #   (req) campaign_id: (Integer)
    #   (req) client_id:   (Integer)
    def perform(**args)
      super

      return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:campaign_id), exception: false).present? &&
                    (client = Client.find_by(id: args[:client_id].to_i))

      if (campaign = client.campaigns.find_by(id: args[:campaign_id].to_i)).present?
        campaign.destroy
      end

      Campaigns::Destroyed::TriggeractionsJob.perform_later(client_id: client.id, campaign_id: args[:campaign_id])
      Campaigns::Destroyed::ClientApiIntegrationsJob.perform_later(client_id: client.id, campaign_id: args[:campaign_id])

      # rubocop:disable Rails/SkipsModelValidations
      Stage.where(campaign_id: args[:campaign_id]).update_all(campaign_id: 0)
      Tag.where(campaign_id: args[:campaign_id]).update_all(campaign_id: 0)
      Task.where(campaign_id: args[:campaign_id]).update_all(campaign_id: 0)
      TrackableLink.where(campaign_id: args[:campaign_id]).update_all(campaign_id: 0)
      # rubocop:enable Rails/SkipsModelValidations

      Contacts::Campaign.where(campaign_id: args[:campaign_id].to_i).destroy_all
      DelayedJob.where(process: 'group_start_campaign', locked_at: nil).where('data @> ?', { apply_campaign_id: args[:campaign_id] }.to_json).delete_all
      DelayedJob.where(process: 'start_campaign', locked_at: nil).where('data @> ?', { campaign_id: args[:campaign_id] }.to_json).delete_all
    end

    def max_run_time
      2400 # seconds (40 minutes)
    end
  end
end
