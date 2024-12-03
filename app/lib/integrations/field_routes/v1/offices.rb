# frozen_string_literal: true

# app/lib/integrations/field_routes/v1/offices.rb
module Integrations
  module FieldRoutes
    module V1
      module Offices
        def office_ids
          reset_attributes
          @result = {}

          fieldroutes_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldRoutes::V1::Offices.office_ids',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{api_url}/office/search"
          )

          @result = (@result.is_a?(Hash) ? @result : nil) || {}
        end

        def offices(office_ids)
          reset_attributes
          @result = {}

          if office_ids.blank? || !office_ids.is_a?(Array)
            @message = 'FieldRoutes office_ids must be an array of integers'
            return @result
          end

          params = { officeIDs: office_ids }

          fieldroutes_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldRoutes::V1::Offices.offices',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   "#{api_url}/office/get"
          )

          @result = (@result.is_a?(Hash) ? @result : [])
        end
      end
    end
  end
end
