# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/offices.rb
module Integration
  module Fieldroutes
    module V1
      module Offices
        # call FieldRoutes API to update ClientApiIntegration.offices
        # Integration::Fieldroutes::V1::Base.new(client_api_integration).refresh_offices
        def refresh_offices
          return unless valid_credentials?

          client_api_integration_offices.update(data: fieldroutes_offices, updated_at: Time.current)
        end

        def offices_last_updated
          client_api_integration_offices_data.present? ? client_api_integration_offices.updated_at : nil
        end

        # return a specific office's data
        # Integration::Fieldroutes::V1::Base.new(client_api_integration).office()
        #   (req) fr_office_id: (Integer)
        def office(fr_office_id)
          return [] if Integer(fr_office_id, exception: false).blank?

          (client_api_integration_offices_data.find { |e| e['officeID'] == fr_office_id.to_s }.presence || {}).deep_symbolize_keys
        end

        # return all offices data
        # Integration::Fieldroutes::V1::Base.new(client_api_integration).offices
        def offices(_args = {})
          client_api_integration_offices_data.map(&:deep_symbolize_keys)
        end

        private

        def client_api_integration_offices
          @client_api_integration_offices ||= @client.client_api_integrations.find_or_create_by(target: 'fieldroutes', name: 'offices')
        end

        def client_api_integration_offices_data
          refresh_offices if client_api_integration_offices.updated_at < 7.days.ago || client_api_integration_offices.data.blank?

          client_api_integration_offices.data.presence || []
        end

        def fieldroutes_office_ids
          @fr_client.office_ids
          update_attributes_from_client

          if @success && @result.dig(:officeIDs).is_a?(Array)
            @result[:officeIDs]
          else
            []
          end
        end

        def fieldroutes_offices
          offices = []

          fieldroutes_office_ids.in_groups_of(1000, false).each do |office_ids|
            new_offices = @fr_client.offices(office_ids)

            offices += new_offices[:offices] if @success && new_offices.dig(:offices).is_a?(Array)
          end

          offices
        end
      end
    end
  end
end
