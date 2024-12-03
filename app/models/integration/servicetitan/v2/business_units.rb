# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/business_units.rb
module Integration
  module Servicetitan
    module V2
      module BusinessUnits
        # call ServiceTitan API to update ClientApiIntegration.business_units
        # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_business_units
        def refresh_business_units
          return unless valid_credentials?

          client_api_integration_business_units.update(data: @st_client.business_units, updated_at: Time.current)
        end

        def business_units_last_updated
          client_api_integration_business_units_data.present? ? client_api_integration_business_units.updated_at : nil
        end

        # return all business_units data
        # Integration::Servicetitan::V2::Base.new(client_api_integration).business_units
        #   (opt) raw: (Boolean / default: false)
        def business_units(args = {})
          if args.dig(:raw)
            client_api_integration_business_units_data.map(&:deep_symbolize_keys)
          else
            client_api_integration_business_units_data.map(&:deep_symbolize_keys)&.map { |bu| [bu[:name], bu[:id]] }&.sort || []
          end
        end

        private

        def client_api_integration_business_units
          @client_api_integration_business_units ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'business_units')
        end

        def client_api_integration_business_units_data
          refresh_business_units if client_api_integration_business_units.updated_at < 7.days.ago || client_api_integration_business_units.data.blank?

          client_api_integration_business_units.data.presence || []
        end
      end
    end
  end
end
