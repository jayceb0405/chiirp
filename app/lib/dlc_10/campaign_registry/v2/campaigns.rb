# frozen_string_literal: true

# app/lib/dlc_10/campaign_registry/v2/campaigns.rb
module Dlc10
  module CampaignRegistry
    module V2
      module Campaigns
        # call CampaignRegistry API for a Campaign
        # tcr_client.campaign()
        #   (req) tcr_campaign_id: (String)
        def campaign(tcr_campaign_id)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign: #{{ tcr_campaign_id: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = {}

          return @result if tcr_campaign_id.blank?

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaign/#{tcr_campaign_id}"
          )

          @result
        end
        # example result:
        # {
        #   :campaignId=>"CKODCJ7",
        #   :cspId=>"SBJAF5P",
        #   :resellerId=>nil,
        #   :status=>"ACTIVE",
        #   :createDate=>"2023-01-23T22:06:29.000Z",
        #   :autoRenewal=>true,
        #   :billedDate=>"2023-08-23T00:00:00.000Z",
        #   :brandId=>"BBTD3MK",
        #   :vertical=>nil,
        #   :usecase=>"MIXED",
        #   :subUsecases=>["CUSTOMER_CARE", "MARKETING", "ACCOUNT_NOTIFICATION"],
        #   :description=>"General Messaging used with all of our Contacts.",
        #   :embeddedLink=>true,
        #   :embeddedPhone=>false,
        #   :termsAndConditions=>true,
        #   :numberPool=>false,
        #   :ageGated=>false,
        #   :directLending=>false,
        #   :subscriberOptin=>true,
        #   :subscriberOptout=>true,
        #   :subscriberHelp=>true,
        #   :sample1=>"Hi customer, welcome to Chiirp!",
        #   :sample2=>"Hi customer, you account is created. Let's set up a time to set your account up.",
        #   :sample3=>"",
        #   :sample4=>"",
        #   :sample5=>"",
        #   :messageFlow=>"End user consent is received by email or on the job.",
        #   :helpMessage=>"Joe's Garage: Reply STOP to opt out.",
        #   :referenceId=>"19_BANDW_a",
        #   :mock=>false,
        #   :nextRenewalOrExpirationDate=>"2023-09-23",
        #   :expirationDate=>nil,
        #   :optinKeywords=>nil,
        #   :optoutKeywords=>"STOP",
        #   :helpKeywords=>"HELP",
        #   :optinMessage=>nil,
        #   :optoutMessage=>"You have been successfully unsubscribed from Joe's Garage.",
        #   :monthlyFee=>10.0
        # }

        # call CampaignRegistry API to delete a campaign
        # tcr_client.campaign_delete(tcr_campaign_id)
        def campaign_delete(tcr_campaign_id)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign_delete: #{{ tcr_campaign_id: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = ''

          return @result if tcr_campaign_id.blank?

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_delete',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaign/#{tcr_campaign_id}"
          )

          @result
        end

        # call CampaignRegistry API for a list of Webhook EventTypes
        # tcr_client.campaign_event_types
        def campaign_event_types
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_event_types',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/eventType"
          )

          @result
        end

        # call CampaignRegistry API to register a Campaign
        # tcr_client.campaign_register()
        #   (req) tcr_brand_id: (String)
        #   (req) campaign:     (Campaign)
        #   (req) phone_vendor: (String) "bandwidth", "sinch" or "twilio"
        def campaign_register(tcr_brand_id, campaign, phone_vendor)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign_register: #{{ tcr_brand_id:, campaign:, phone_vendor: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = {}

          return @result unless tcr_brand_id.to_s.present? && campaign.is_a?(Clients::Dlc10::Campaign) && phone_vendor.to_s.present?

          data = {
            brandId:            tcr_brand_id,
            vertical:           campaign.vertical,
            usecase:            campaign.use_case,
            subUsecases:        campaign.sub_use_cases,
            # resellerId: "string",
            description:        campaign.description,
            embeddedLink:       campaign.embedded_link,
            embeddedPhone:      campaign.embedded_phone,
            numberPool:         campaign.number_pool,
            ageGated:           campaign.age_gated,
            directLending:      campaign.direct_lending,
            subscriberOptin:    true,
            subscriberOptout:   true,
            subscriberHelp:     true,
            sample1:            campaign.sample1,
            sample2:            campaign.sample2,
            sample3:            campaign.sample3,
            sample4:            campaign.sample4,
            sample5:            campaign.sample5,
            messageFlow:        campaign.message_flow,
            mnoIds:             [10_017, 10_035, 10_037, 10_038],
            optinKeywords:      'JOIN,START',
            optoutKeywords:     'STOP,STOPALL,UNSUBSCRIBE',
            helpKeywords:       'HELP,SUPPORT',
            optinMessage:       campaign.brand.opt_in_message,
            optoutMessage:      campaign.brand.opt_out_message,
            helpMessage:        campaign.brand.help_message,
            referenceId:        "#{campaign.id}_#{tcr_dca_id(phone_vendor)}_a",
            autoRenewal:        campaign.auto_renewal,
            # tag: [],
            affiliateMarketing: campaign.affiliate_marketing
          }
          tcr_request(
            body:                  data,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_register',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaignBuilder"
          )

          @result
        end
        # @result example
        # {
        #   :campaignId=>"CULNBNY",
        #   :mnoMetadata=>{
        #     :"10017"=>{:tpmScope=>"CAMPAIGN", :minMsgSamples=>2, :msgClass=>"F", :reqSubscriberOptout=>true, :mnoReview=>false, :mmsTpm=>150, :noEmbeddedPhone=>false, :mno=>"AT&T", :tpm=>240, :reqSubscriberHelp=>true, :reqSubscriberOptin=>true, :mnoSupport=>true, :noEmbeddedLink=>false, :qualify=>true},
        #     :"10035"=>{:minMsgSamples=>1, :reqSubscriberHelp=>true, :reqSubscriberOptout=>false, :brandDailyCap=>2000, :reqSubscriberOptin=>true, :mnoReview=>false, :mnoSupport=>true, :brandTier=>"LOW", :noEmbeddedLink=>false, :noEmbeddedPhone=>false, :qualify=>true, :mno=>"T-Mobile"},
        #     :"10037"=>{:minMsgSamples=>1, :reqSubscriberHelp=>false, :reqSubscriberOptout=>false, :reqSubscriberOptin=>false, :mnoReview=>false, :mnoSupport=>true, :noEmbeddedLink=>false, :noEmbeddedPhone=>false, :qualify=>true, :mno=>"US Cellular"},
        #     :"10038"=>{:minMsgSamples=>1, :reqSubscriberHelp=>false, :reqSubscriberOptout=>false, :reqSubscriberOptin=>false, :mnoReview=>false, :mnoSupport=>true, :noEmbeddedLink=>false, :noEmbeddedPhone=>false, :qualify=>true, :mno=>"Verizon Wireless"}
        #   }
        # }

        # share a Campaign in CampaignRegistry with Connectivity Partner
        # tcr_client.campaign_share()
        #   (req) tcr_campaign_id: (String)
        #   (req) phone_vendor:    (String) "bandwidth", "sinch" or "twilio"
        def campaign_share(tcr_campaign_id, phone_vendor)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign_share: #{{ tcr_campaign_id:, phone_vendor: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = {}

          return @result if tcr_campaign_id.blank? || phone_vendor.blank?

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_share',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaign/#{tcr_campaign_id}/sharing/#{tcr_dca_id(phone_vendor)}"
          )

          @result
        end
        # example TCR Campaign Share response
        # {
        #   downstreamCnpId: 'SBJAF5P',
        #   upstreamCnpId:   'BANDW',
        #   sharingStatus:   'ACCEPTED',
        #   explanation:     nil,
        #   sharedDate:      '2024-03-29T22:10:59.000Z',
        #   statusDate:      '2024-03-29T22:10:59.000Z',
        #   cnpMigration:    false
        # }

        # call CampaignRegistry API to determine who Campaign is shared with
        # tcr_client.campaign_sharing(tcr_campaign_id)
        # vendor: "bandwidth" or "twilio"
        def campaign_sharing(tcr_campaign_id)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign_sharing: #{{ tcr_campaign_id: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = {}

          return @result if tcr_campaign_id.blank?

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_share',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaign/#{tcr_campaign_id}/sharing"
          )

          @result
        end

        # call CampaignRegistry API for Campaign types defined for Brand
        # tcr_client.campaign_types(brand_id)
        def campaign_types(brand_id)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign_types: #{{ brand_id: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = []

          return @result if brand_id.to_s.blank?

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_types',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaignBuilder/brand/#{brand_id}"
          )

          @result
        end

        # call CampaignRegistry API to update a Campaign
        # tcr_client.campaign_update(campaign: Hash)
        def campaign_update(args = {})
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaign_update: #{{ args: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          campaign = args.dig(:campaign)
          @result  = {}

          return @result unless campaign.is_a?(Hash)

          data = {
            description: campaign.dig(:description),
            sample1:     campaign.dig(:sample1),
            sample2:     campaign.dig(:sample2),
            sample3:     campaign.dig(:sample3),
            sample4:     campaign.dig(:sample4),
            sample5:     campaign.dig(:sample5),
            autoRenewal: campaign.dig(:auto_renewal)
          }
          tcr_request(
            body:                  data,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaign_update',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/campaign/#{campaign.dig(:tcr_campaign_id)}"
          )

          @result
        end

        # call CampaignRegistry API for a list of Campaigns
        # tcr_client.campaigns()
        #   (opt) tcr_brand_id: (String)
        def campaigns(tcr_brand_id = '')
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.campaigns: #{{ tcr_brand_id: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result   = []
          response  = []
          page      = 1
          page_size = 500

          loop do
            params = { page:, recordsPerPage: page_size }
            params[:brandId] = tcr_brand_id if tcr_brand_id.present?
            tcr_request(
              body:                  nil,
              error_message_prepend: 'Dlc10::CampaignRegistry::V2::Campaigns.campaigns',
              method:                'get',
              params:,
              default_result:        [],
              url:                   "#{base_api_url}/#{api_version}/campaign"
            )

            response += @result.dig(:records)
            page     += 1
            break if page > (@result.dig(:totalRecords).to_f / page_size).ceil
          end

          @success = response.present?

          @result = response
        end

        # call CampaignRegistry API for Campaign types approved for Brand
        # tcr_client.qualified_campaign_types(brand_id)
        def qualified_campaign_types(brand_id)
          Rails.logger.info "Dlc10::CampaignRegistry::V2::Campaigns.qualified_campaign_types: #{{ brand_id: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          reset_attributes
          @result = self.campaign_types(brand_id)
          @result.delete_if { |t| !t.dig(:mnoMetadata, :'10017', :qualify) || !t.dig(:mnoMetadata, :'10035', :qualify) || !t.dig(:mnoMetadata, :'10037', :qualify) || !t.dig(:mnoMetadata, :'10038', :qualify) }
        end
      end
    end
  end
end
