# frozen_string_literal: true

# app/lib/dlc_10/campaign_registry/v2/enums.rb
module Dlc10
  module CampaignRegistry
    module V2
      module Enums
        # call CampaignRegistry API for a list of Brand altBusinessIdType
        # tcr_client.brand_alt_business_id_types
        def brand_alt_business_id_types
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.brand_alt_business_id_types',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/altBusinessIdType"
          )

          @result
        end

        # call CampaignRegistry API for a list of Brand entityTypes
        # tcr_client.brand_entity_types
        def brand_entity_types
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.brand_entity_types',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/entityType"
          )

          @result
        end

        # call CampaignRegistry API for a list of Brand Relationships
        # tcr_client.brand_relationships
        def brand_relationships
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.brand_relationships',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/brandRelationship"
          )

          @result
        end

        # call CampaignRegistry API for a list of Brand Stock Exchange
        # tcr_client.brand_stock_exchanges
        def brand_stock_exchanges
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.brand_stock_exchanges',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/stockExchange"
          )

          @result
        end

        # call CampaignRegistry API for a list of Brand Verticals
        # tcr_client.brand_verticals
        def brand_verticals
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.brand_verticals',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/vertical"
          )

          @result
        end

        # call CampaignRegistry API for a list of Direct Connect Aggregators (DCA)
        # tcr_client.direct_connect_aggregators
        # "TWILO", "Twilio"
        # "BANDW", "Bandwidth"
        def direct_connect_aggregators
          reset_attributes
          @result = []

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.direct_connect_aggregators',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/dca"
          )

          @result
        end

        # call CampaignRegistry API for Campaign use cases supported
        # tcr_client.use_cases
        def use_cases
          reset_attributes
          @result = {}

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Enums.use_cases',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/enum/usecase"
          )

          @result
        end

        # filter CampaignRegistry use cases for only valid sub-use cases
        # tcr_client.valid_sub_use_cases
        def valid_sub_use_cases
          reset_attributes
          @result = self.use_cases.find_all { |_k, v| v[:validSubUsecase] }.to_h
        end
      end
    end
  end
end
