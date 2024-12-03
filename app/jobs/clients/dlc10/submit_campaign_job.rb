# frozen_string_literal: true

module Clients
  module Dlc10
    class SubmitCampaignJob < ApplicationJob
      # Clients::Dlc10::SubmitCampaignJob.perform_now()
      # Clients::Dlc10::SubmitCampaignJob.set(wait_until: 1.day.from_now).perform_later()
      # Clients::Dlc10::SubmitCampaignJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'dlc10_campaign_create').to_s
      end

      # perform the ActiveJob
      #   (req) dlc10_campaign_id: (Integer) the Clients::Dlc10::Campaign id to process
      def perform(**args)
        return unless args.dig(:dlc10_campaign_id).to_i.positive? && (dlc10_campaign = Clients::Dlc10::Campaign.find_by(id: args[:dlc10_campaign_id].to_i))

        errors = dlc10_campaign.charge_and_register

        return unless errors.any?

        JsonLog.info 'Clients::Dlc10::SubmitCampaignJob', { args:, dlc10_campaign:, errors: }, client_id: dlc10_campaign.brand.client_id

        title = '10DLC Use Case Submittal Failed'
        content = <<~CONTENT
          Please contact support to resolve the following issues:
          #{errors.full_messages.join(', ')}
        CONTENT
        Users::SendPushOrTextJob.perform_later(
          content:,
          title:,
          user_id: dlc10_campaign.client.def_user.id
        )
      end
    end
  end
end
