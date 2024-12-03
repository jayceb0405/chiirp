# frozen_string_literal: true

# app/lib/dlc_10/campaign_registry/v2/brands.rb
module Dlc10
  module CampaignRegistry
    module V2
      module Brands
        # call Campaign Registry API for a specific brand
        # tcr_client.brand(tcr_brand_id)
        def brand(tcr_brand_id)
          JsonLog.info 'Dlc10::CampaignRegistry::V2::Brands.brand', { tcr_brand_id: }
          reset_attributes
          @result = {}

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Brands.brand',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/brand/#{tcr_brand_id}"
          )

          @result
        end

        # call CampaignRegistry to delete a Brand
        # tcr_client.brand_delete(tcr_brand_id)
        def brand_delete(tcr_brand_id)
          JsonLog.info 'Dlc10::CampaignRegistry::V2::Brands.brand_delete', { tcr_brand_id: }
          reset_attributes
          @result = ''

          return @result if tcr_brand_id.blank?

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Brands.brand_delete',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/brand/#{tcr_brand_id}"
          )

          @result
        end

        # call CampaignRegistry API to get brand feedback on errors
        # tcr_client.brand_feedback()
        #   (req) tcr_brand_id: (String)
        def brand_feedback(tcr_brand_id)
          JsonLog.info 'Dlc10::CampaignRegistry::V2::Brands.brand_feedback', { tcr_brand_id: }
          reset_attributes
          @result = {}

          if tcr_brand_id.blank?
            @message = 'Brand ID is required.'
            return @result
          end

          @result = tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Brands.brand_feedback',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/brand/feedback/#{tcr_brand_id}"
          ).dig(:category) || []
        end

        # call CampaignRegistry API to register a Brand
        # tcr_client.brand_register()
        #   (req) brand: (Hash)
        def brand_register(brand)
          JsonLog.info 'Dlc10::CampaignRegistry::V2::Brands.brand_register', { brand: }
          reset_attributes
          @result = {}

          if brand.blank? || !brand.is_a?(Hash)
            @message = 'Brand data is required.'
            return @result
          end

          data = format_brand_for_registration(brand)

          tcr_request(
            body:                  data,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Brands.brand_register',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/brand/nonBlocking"
          )

          @result
        end

        # update brand data with TCR
        # tcr_client.brand_update()
        #   (req) brand: (Hash)
        def brand_update(brand)
          JsonLog.info 'Dlc10::CampaignRegistry::V2::Brands.brand_update', { brand: }
          reset_attributes
          @result = {}

          if brand.blank? || !brand.is_a?(Hash)
            @message = 'Brand data is required.'
            return @result
          elsif brand.dig(:tcr_brand_id).blank?
            @message = 'Brand ID must be provided.'
            return @result
          end

          data = format_brand_for_registration(brand)

          tcr_request(
            body:                  data,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Brands.brand_update',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/brand/#{brand.dig(:tcr_brand_id)}"
          )

          @result
        end

        # call CampaignRegistry API for a list of Brands
        # tcr_client.brands
        def brands
          reset_attributes
          response = []

          page                = 1
          page_size           = 500

          loop do
            tcr_request(
              body:                  nil,
              error_message_prepend: 'Dlc10::CampaignRegistry::V2::Brands.brands',
              method:                'get',
              params:                { page:, recordsPerPage: page_size },
              default_result:        [],
              url:                   "#{base_api_url}/#{api_version}/brand"
            )

            response += @result.dig(:records)
            page     += 1
            break if page > (@result.dig(:totalRecords).to_f / page_size).ceil
          end

          @success = response.present?

          @result = response
        end

        private

        # format the data for a brand to be registered with TCR
        #   (req) brand: (Hash)
        def format_brand_for_registration(brand)
          return {} if brand.blank? || !brand.is_a?(Hash)

          {
            entityType:        brand.dig(:entity_type).to_s,
            firstName:         brand.dig(:firstname).to_s,
            lastName:          brand.dig(:lastname).to_s,
            displayName:       brand.dig(:display_name).to_s,
            companyName:       brand.dig(:company_name).to_s,
            ein:               brand.dig(:ein).to_s,
            einIssuingCountry: brand.dig(:ein_country).to_s,
            phone:             "+1#{brand.dig(:phone)}",
            street:            brand.dig(:street).to_s,
            city:              brand.dig(:city).to_s,
            state:             brand.dig(:state).to_s,
            postalCode:        brand.dig(:zipcode).to_s,
            country:           brand.dig(:country).to_s,
            email:             brand.dig(:email).to_s,
            stockSymbol:       brand.dig(:stock_symbol).to_s,
            stockExchange:     brand.dig(:stock_exchange).to_s,
            ipAddress:         brand.dig(:ip_address).to_s,
            website:           brand.dig(:website).to_s,
            brandRelationship: brand.dig(:brand_relationship).to_s,
            vertical:          brand.dig(:vertical).to_s,
            altBusinessId:     brand.dig(:alt_business_id).to_s,
            altBusinessIdType: brand.dig(:alt_business_id_type).to_s,
            referenceId:       brand.dig(:id).to_s,
            mock:              Rails.env.development? || Rails.env.test?
          }
        end
      end
    end
  end
end
