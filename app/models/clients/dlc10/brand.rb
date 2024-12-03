# frozen_string_literal: true

# app/models/clients/dlc10/brand.rb
module Clients
  module Dlc10
    class Brand < ApplicationRecord
      self.table_name = 'client_dlc10_brands'

      belongs_to :client

      has_many   :campaigns, dependent: :destroy, class_name: 'Clients::Dlc10::Campaign', foreign_key: 'dlc10_brand_id', inverse_of: :brand

      # determine if any TCR Campaigns are active
      def active_campaigns?
        self.campaigns.map(&:verified?).include?(true)
      end

      # collect specific data pertaining to use case
      def available_sub_use_cases(use_case)
        tcr_client    = ::Dlc10::CampaignRegistry::V2::Base.new
        campaign_type = tcr_client.qualified_campaign_types(self.tcr_brand_id).find { |t| t[:usecase] == use_case }

        if campaign_type.present?
          {
            min_options:      campaign_type.dig(:minSubUsecases).to_i,
            max_options:      campaign_type.dig(:maxSubUsecases).to_i,
            req_sample_count: campaign_type.dig(:mnoMetadata)&.map { |_mno, values| values.dig(:minMsgSamples).to_i }&.max || 1,
            use_cases:        tcr_client.valid_sub_use_cases.keys.map(&:to_s).map { |k| [k == '2FA' ? k : k.titleize, k] },
            mo_charge:        campaign_type.dig(:monthlyFee).to_d
          }
        else
          {}
        end
      end

      def campaigns_amount_due
        response = 0.0

        self.campaigns.find_each do |dlc10_campaign|
          next_mo_date = dlc10_campaign.next_mo_date

          while next_mo_date < (Chronic.parse(dlc10_campaign.tcr_campaign&.dig(:nextRenewalOrExpirationDate)) || next_mo_date)
            response += dlc10_campaign.mo_charge
            next_mo_date = (next_mo_date + 1.month).end_of_month
          end
        end

        response
      end

      def help_message(include_help_link = true)
        "#{client.name}: For help: #{include_help_link ? website.presence || support_email.presence || ActionController::Base.helpers.number_to_phone(client.def_user.default_from_twnumber&.phonenumber.to_s) : 'xxx'}. Reply STOP to opt out. Text JOIN to opt in."
      end

      # interpret TCR Brand feedback
      def feedback
        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        # tcr_client.brand_feedback(self.tcr_brand_id)
        tcr_client.brand_feedback('B1GF1JF')

        if tcr_client.success?
          tcr_client.result.map { |f| f.dig(:description) }
        else
          []
        end
      end

      def opt_in_message
        "#{client.name}: Message frequency varies. Text HELP for help. Text STOP to opt out. Message & data rates may apply."
      end

      def opt_out_message
        "Successfully unsubscribed from #{client.name}. No further messages will be sent. Text JOIN to opt in."
      end

      # determine if a field is ok to edit
      def ok2edit_brand_field?(field_name)
        return false if field_name.blank?

        case field_name
        when 'ein', 'ein_country', 'entity_type', 'company_name'
          !self.active_campaigns?
        when 'firstname', 'lastname', 'display_name', 'website', 'street', 'city', 'state', 'zipcode', 'country', 'email', 'phone', 'vertical', 'stock_symbol', 'stock_exchange'
          true
        else
          false
        end
      end

      def register
        JsonLog.info 'Clients::Dlc10::Brand.register', { client_dlc10_brand: self }
        return [''] if self.tcr_brand_id.present? && self.submitted_at.present? && self.verified_at.present?

        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        tcr_client.brand_register(self.attributes.symbolize_keys)

        self.update(tcr_brand_id: tcr_client.result.dig(:brandId).to_s, submitted_at: Time.current, verified_at: tcr_client.result.dig(:identityStatus)&.casecmp?('VERIFIED') ? Time.current : nil) if tcr_client.success?

        tcr_client.message
      end

      def update_registration
        JsonLog.info 'Clients::Dlc10::Brand.update', { client_dlc10_brand: self }
        tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
        tcr_client.brand_update(self.attributes.symbolize_keys)

        self.update(tcr_brand_id: tcr_client.result.dig(:brandId).to_s, resubmitted_at: Time.current, verified_at: tcr_client.result.dig(:identityStatus)&.casecmp?('VERIFIED') ? Time.current : nil) if tcr_client.success?

        tcr_client.message
      end

      def verified?
        if self.tcr_brand_id.present? && ::Dlc10::CampaignRegistry::V2::Base.new.brand(self.tcr_brand_id)&.dig(:identityStatus)&.casecmp?('VERIFIED')
          self.update(verified_at: Time.current) if self.verified_at.nil?
          true
        else
          self.update(verified_at: nil)
          false
        end
      end
    end
  end
end
