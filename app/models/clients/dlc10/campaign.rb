# frozen_string_literal: true

# app/models/clients/dlc10/campaign.rb
module Clients
  module Dlc10
    class Campaign < ApplicationRecord
      self.table_name = 'client_dlc10_campaigns'

      belongs_to :brand, class_name: 'Clients::Dlc10::Brand', foreign_key: 'dlc10_brand_id', inverse_of: :campaigns
      has_many   :twnumbers, dependent: :nullify, foreign_key: 'dlc10_campaign_id', inverse_of: :dlc10_campaign
      has_one    :client, through: :brand

      after_initialize :after_initialize_actions

      def charge_and_register
        charge_result = if !self.client.dlc10_charged || self.client.client_transactions.find_by(setting_key: 'dlc10_campaign_charge', setting_value: 20.0).present?
                          { success: true }
                        else
                          self.client.charge_card(charge_amount: 20.00, setting_key: 'dlc10_campaign_charge')
                        end

        if charge_result[:success]
          errors = self.register(self.client.phone_vendor)

          errors.each do |m|
            self.errors.add(:base, m)
          end

          self.share(self.client.phone_vendor) if self.tcr_campaign_id.present?
        else
          self.errors.add(:base, charge_result[:error_message])
        end

        JsonLog.info 'Clients::Dlc10::Campaign.charge_and_register', { dlc10_campaign: self, errors: self.errors, charge_result: }, client_id: self.brand.client_id if errors.any?

        self.errors
      end

      def charge_fee(fee, key)
        self.dlc10_brand.client.deduct_credits(credits_amt: fee, key:)
        self.dlc10_brand.client.recharge_credits
      end

      def self.default_options(client_name)
        {
          description:   'General messaging with customers and leads regarding the services we offer.',
          name:          'New Use Case',
          message_flow:  'End user consent is received by email, over the phone, on a website widget/form or in-person on the job.',
          sub_use_cases: %w[ACCOUNT_NOTIFICATION CUSTOMER_CARE MARKETING],
          use_case:      'MIXED',
          vertical:      'PROFESSIONAL',
          mo_charge:     12.0
        }
      end

      # register a campaign with TCR
      def register(phone_vendor)
        return [] if phone_vendor.to_s.blank?
        return [] if self.tcr_campaign_id.present?

        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        tcr_client.campaign_register(self.brand.tcr_brand_id, self, phone_vendor)

        self.update(tcr_campaign_id: tcr_client.result[:campaignId]) if tcr_client.success? && tcr_client.result.dig(:campaignId).present?

        tcr_client.message
      end

      # share a registered TCR campaign with phone vendor
      def share(phone_vendor)
        JsonLog.info 'Clients::Dlc10::Campaign.share', { phone_vendor: }
        return if self.tcr_campaign_id.blank? || self.shared?

        # inform TCR that campaign will be shared with phone vendor
        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        tcr_client.campaign_share(self.tcr_campaign_id, phone_vendor)

        # share campaign with phone vendor
        dlc10_client = ::Dlc10::Router.new(phone_vendor)
        dlc10_client.campaign_share(self.tcr_campaign_id)

        return unless dlc10_client.success?

        self.shared_at   = dlc10_client.result.dig(:created_at)
        self.accepted_at = dlc10_client.result.dig(:created_at) if dlc10_client.result.dig(:status).casecmp?('ACTIVE')
        self.save
      end
      # example TCR Campaign Share response:
      # {
      #   downstreamCnpId: 'SBJAF5P',
      #   upstreamCnpId:   'BANDW',
      #   sharingStatus:   'ACCEPTED',
      #   explanation:     nil,
      #   sharedDate:      '2024-03-29T22:10:59.000Z',
      #   statusDate:      '2024-03-29T22:10:59.000Z',
      #   cnpMigration:    false
      # }
      # example phone vendor Campaign Share response:
      # {
      #   :CampaignId=>"CBTANC9",
      #   :Description=>"General Messaging with Contacts",
      #   :MessageClass=>"Campaign-T",
      #   :CreateDate=>"2021-10-26T13:45:54Z",
      #   :Status=>"ACTIVE",
      #   :MnoStatusList=>{:MnoStatus=>[{:MnoName=>"ATT", :MnoId=>"10017", :Status=>"APPROVED"}, {:MnoName=>"TMO", :MnoId=>"10035", :Status=>"APPROVED"}]}
      # }

      def share_accepted?
        JsonLog.info 'Clients::Dlc10::Campaign.share_accepted', { client_dlc10_campaign: self }
        return false if self.tcr_campaign_id.blank?
        return true if self.accepted_at

        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        tcr_client.campaign_sharing(self.tcr_campaign_id)

        if tcr_client.success? && tcr_client.result.dig(:sharedByMe, :sharingStatus).to_s.casecmp?('ACCEPTED')
          self.update(accepted_at: tcr_client.result.dig(:sharedByMe, :statusDate))
          true
        else
          false
        end
      end

      def share_phone_number(twnumber)
        JsonLog.info 'Clients::Dlc10::Campaign.share_phone_number', { twnumber:, client_dlc10_campaign: self }
        return unless self.verified?

        if self.tcr_campaign_id.blank?
          self.register(twnumber.phone_vendor)
          self.reload
        end

        return if self.tcr_campaign_id.blank?
        return unless self.shared?

        dlc10_client = ::Dlc10::Router.new(twnumber.phone_vendor)
        dlc10_client.campaign_phone_number(self.tcr_campaign_id, twnumber.phonenumber)
        twnumber.update(dlc10_campaign_id: self.id) if dlc10_client.success?
        self.update(accepted_at: dlc10_client.result.dig(:statusDate)) if dlc10_client.result.dig(:upstreamCnpId).to_s.casecmp?('bandw')
      end

      def shared?
        JsonLog.info 'Clients::Dlc10::Campaign.shared', { client_dlc10_campaign: self }
        return false if self.tcr_campaign_id.blank?
        return true if self.accepted_at || self.shared_at

        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        tcr_client.campaign_sharing(self.tcr_campaign_id)

        if tcr_client.success? && tcr_client.result.dig(:sharedByMe, :sharedDate).present?
          self.update(shared_at: tcr_client.result.dig(:sharedByMe, :sharedDate))
          true
        else
          false
        end
      end

      def tcr_campaign
        @tcr_campaign ||= ::Dlc10::CampaignRegistry::V2::Base.new.campaign(self.tcr_campaign_id)
      end

      def tcr_campaign_renewal_date
        self.tcr_campaign.dig(:autoRenewal).to_bool ? Time.use_zone(self.brand.client.time_zone) { Chronic.parse(self.tcr_campaign.dig(:nextRenewalOrExpirationDate)) } : nil
      end

      def verified?
        self.tcr_campaign&.dig(:status)&.casecmp?('ACTIVE')
      end

      private

      def after_initialize_actions
        self.mo_charge = self.brand.available_sub_use_cases(self.use_case).dig(:mo_charge).to_d + 2.0 if self.new_record? && self.mo_charge.to_i.zero? && self.use_case.present?
        @tcr_campaign = nil
      end
    end
  end
end
