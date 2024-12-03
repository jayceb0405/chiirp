# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/payments/types.rb
module Integration
  module Servicetitan
    module V2
      module Payments
        module Types
          # call ServiceTitan API to update ClientApiIntegration.payment_types
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_payment_types
          def refresh_payment_types
            return unless valid_credentials?

            client_api_integration_payment_types.update(data: @st_client.payment_types, updated_at: Time.current)
          end

          def payment_types_last_updated
            client_api_integration_payment_types_data.present? ? client_api_integration_payment_types.updated_at : nil
          end

          # return all payment_types data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).payment_types
          #   (opt) raw: (Boolean / default: false)
          def payment_types(args = {})
            if args.dig(:raw)
              client_api_integration_payment_types_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_payment_types_data.map(&:deep_symbolize_keys)&.map { |jt| [jt[:name], jt[:id]] }&.sort || []
            end
          end

          private

          def client_api_integration_payment_types
            @client_api_integration_payment_types ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'payment_types')
          end

          def client_api_integration_payment_types_data
            refresh_payment_types if client_api_integration_payment_types.updated_at < 7.days.ago || client_api_integration_payment_types.data.blank?

            client_api_integration_payment_types.data.presence || []
          end
        end
      end
    end
  end
end
