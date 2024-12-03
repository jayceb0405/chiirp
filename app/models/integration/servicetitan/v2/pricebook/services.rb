# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/pricebook/services.rb
module Integration
  module Servicetitan
    module V2
      module Pricebook
        module Services
          # call ServiceTitan API to update ClientApiIntegration.pricebook_services
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_pricebook_services
          def refresh_pricebook_services
            return unless valid_credentials?

            client_api_integration_pricebook_services.update(data: @st_client.pb_services, updated_at: Time.current)
          end

          def pricebook_services_last_updated
            client_api_integration_pricebook_services_data.present? ? client_api_integration_pricebook_services.updated_at : nil
          end

          # return all pricebook_services data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).pricebook_services
          #   (opt) raw: (Boolean / default: false)
          def pricebook_services(args = {})
            if args.dig(:raw)
              client_api_integration_pricebook_services_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_pricebook_services_data.map(&:deep_symbolize_keys)&.map { |c| [c[:name], c[:id]] } || []
            end
          end

          private

          def client_api_integration_pricebook_services
            @client_api_integration_pricebook_services ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'pricebook_services')
          end

          def client_api_integration_pricebook_services_data
            refresh_pricebook_services if client_api_integration_pricebook_services.updated_at < 7.days.ago || client_api_integration_pricebook_services.data.blank?

            client_api_integration_pricebook_services.data.presence || []
          end
        end
      end
    end
  end
end
