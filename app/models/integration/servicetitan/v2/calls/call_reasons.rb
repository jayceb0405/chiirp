# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/jobs/call_reasons.rb
module Integration
  module Servicetitan
    module V2
      module Calls
        module CallReasons
          # call ServiceTitan API to update ClientApiIntegration.call_reasons
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_call_reasons
          def refresh_call_reasons
            return unless valid_credentials?

            client_api_integration_call_reasons.update(data: @st_client.call_reasons, updated_at: Time.current)
          end

          def call_reasons_last_updated
            client_api_integration_call_reasons_data.present? ? client_api_integration_call_reasons.updated_at : nil
          end

          # return all call_reasons data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).call_reasons
          #   (opt) raw: (Boolean / default: false)
          def call_reasons(args = {})
            if args.dig(:raw)
              client_api_integration_call_reasons_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_call_reasons_data.map(&:deep_symbolize_keys)&.map { |cr| [cr[:name], cr[:id]] }&.map { |y| y unless y.compact_blank.length != 2 }&.compact_blank&.sort || []
            end
          end

          private

          def client_api_integration_call_reasons
            @client_api_integration_call_reasons ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'call_reasons')
          end

          def client_api_integration_call_reasons_data
            refresh_call_reasons if client_api_integration_call_reasons.updated_at < 7.days.ago || client_api_integration_call_reasons.data.blank?

            client_api_integration_call_reasons.data.presence || []
          end
        end
      end
    end
  end
end
