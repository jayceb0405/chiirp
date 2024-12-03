# frozen_string_literal: true

# app/lib/dlc_10/campaign_registry/v2/resellers.rb
module Dlc10
  module CampaignRegistry
    module V2
      module Resellers
        # call CampaignRegistry API for a list of Resellers
        # tcr_client.resellers
        def resellers
          reset_attributes
          @result   = []
          response  = []
          page      = 1
          page_size = 500

          loop do
            tcr_request(
              body:                  nil,
              error_message_prepend: 'Dlc10::CampaignRegistry::V2::Resellers.resellers',
              method:                'get',
              params:                { page:, recordsPerPage: page_size },
              default_result:        [],
              url:                   "#{base_api_url}/#{api_version}/reseller"
            )

            response += @result.dig(:records)
            page     += 1
            break if page > (@result.dig(:totalRecords).to_f / page_size).ceil
          end

          @success = response.present?

          @result = response
        end
      end
    end
  end
end
