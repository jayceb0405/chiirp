# frozen_string_literal: true

# app/lib/integrations/ggl/my_business_business_information/locations.rb
module Integrations
  module Ggl
    module MyBusinessBusinessInformation
      # Google API calls to support Business Profile Locations
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Locations
        # get a Google Location for an Account
        # ggl_client.my_business_location
        # (req) location_id: (String / ex: 'locations/12247487312543151044')
        def my_business_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID is required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::MyBusinessBusinessInformation::Locations.my_business_location',
            method:                'get',
            params:                { readMask: self.location_read_mask },
            default_result:        @result,
            url:                   "#{my_business_business_information_base_url}/#{my_business_business_information_base_version}/#{location_id}"
          )

          @result
        end

        # get a list of Google Locations for an Account
        # ggl_client.my_business_locations()
        # (req) account_id: (String / ex: 'accounts/106702836638822736000')
        # https://developers.google.com/my-business/reference/businessinformation/rest/v1/accounts.locations/list
        def my_business_locations(account_id)
          reset_attributes
          response = []

          if account_id.blank?
            @message = 'Account ID is required.'
            return response
          end

          # pageSize: Optional. How many locations to fetch per page. Default value is 10 if not set. Minimum is 1, and maximum page size is 100.

          params = {
            readMask: self.location_read_mask,
            pageSize: 100
          }

          loop do
            self.google_request(
              body:                  nil,
              error_message_prepend: 'Integrations::Ggl::MyBusinessBusinessInformation::Locations.my_business_locations',
              method:                'get',
              params:,
              default_result:        @result,
              url:                   "#{my_business_business_information_base_url}/#{my_business_business_information_base_version}/#{account_id}/locations"
            )

            if @success && @result.is_a?(Hash)
              response += @result.dig(:locations) || []
              break if (params[:pageToken] = @result.dig(:nextPageToken)).blank?
            else
              response = []
              break
            end
          end

          @result = response
        end

        private

        def location_read_mask
          'name,title,storeCode,phoneNumbers,categories,storefrontAddress,websiteUri,regularHours,serviceArea,labels,metadata,profile,relationshipData'
        end
      end
    end
  end
end
