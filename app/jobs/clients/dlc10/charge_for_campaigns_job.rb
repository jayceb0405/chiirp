# frozen_string_literal: true

module Clients
  module Dlc10
    class ChargeForCampaignsJob < ApplicationJob
      # Clients::Dlc10::ChargeForCampaignsJob.perform_now()
      # Clients::Dlc10::ChargeForCampaignsJob.set(wait_until: 1.day.from_now).perform_later()
      # Clients::Dlc10::ChargeForCampaignsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'dlc10_charge_for_campaigns').to_s
      end

      # perform the ActiveJob
      # charge Client accounts for monthly fees
      def perform(**args)
        Clients::Dlc10::Campaign.where.not(accepted_at: nil).where('next_mo_date <= ?', Date.current).joins(brand: :client).where('clients.data @> ?', { active: true }.to_json).find_each do |dlc10_campaign|
          charge_result = dlc10_campaign.brand.client.dlc10_charged ? dlc10_campaign.brand.client.charge_card(charge_amount: dlc10_campaign.mo_charge, setting_key: 'dlc10_campaign_mo_charge') : { success: true }
          dlc10_campaign.update(next_mo_date: (dlc10_campaign.next_mo_date + 1.month).end_of_month) if charge_result[:success]
        end
      end
    end
  end
end
