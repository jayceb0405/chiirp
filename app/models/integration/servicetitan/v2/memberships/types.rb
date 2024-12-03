# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/memberships/types.rb
module Integration
  module Servicetitan
    module V2
      module Memberships
        module Types
          # call ServiceTitan API to update ClientApiIntegration.membership_types
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_membership_types
          def refresh_membership_types
            return unless valid_credentials?

            client_api_integration_membership_types.update(data: @st_client.membership_types, updated_at: Time.current)
          end

          def membership_type_name(st_membership_type_id)
            membership_types.find { |m| m[1] == st_membership_type_id }&.first.to_s
          end

          def membership_types_last_updated
            client_api_integration_membership_types_data.present? ? client_api_integration_membership_types.updated_at : nil
          end

          # return all membership_types data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).membership_types
          #   (opt) raw: (Boolean / default: false)
          def membership_types(args = {})
            if args.dig(:raw)
              client_api_integration_membership_types_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_membership_types_data.map(&:deep_symbolize_keys)&.map { |jt| [jt[:name], jt[:id]] }&.sort || []
            end
          end

          private

          def client_api_integration_membership_types
            @client_api_integration_membership_types ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'membership_types')
          end

          def client_api_integration_membership_types_data
            refresh_membership_types if client_api_integration_membership_types.updated_at < 7.days.ago || client_api_integration_membership_types.data.blank?

            client_api_integration_membership_types.data.presence || []
          end
        end
      end
    end
  end
end
