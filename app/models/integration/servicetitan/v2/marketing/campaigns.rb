# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/marketing/campaigns.rb
module Integration
  module Servicetitan
    module V2
      module Marketing
        module Campaigns
          # call ServiceTitan API to update ClientApiIntegration.campaigns
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_campaigns
          def refresh_campaigns
            return unless valid_credentials?

            client_api_integration_campaigns.update(data: @st_client.campaigns, updated_at: Time.current)
          end

          def campaigns_last_updated
            client_api_integration_campaigns_data.present? ? client_api_integration_campaigns.updated_at : nil
          end

          # Integration::Servicetitan::V2::Base.new(client_api_integration).campaigns
          #   (opt) raw: (Boolean / default: false)
          def campaigns(args = {})
            if args.dig(:raw)
              client_api_integration_campaigns_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_campaigns_data.map(&:deep_symbolize_keys)&.map { |c| [c[:name], c[:id]] }&.sort || []
            end
          end

          private

          def client_api_integration_campaigns
            @client_api_integration_campaigns ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'campaigns')
          end

          def client_api_integration_campaigns_data
            refresh_campaigns if client_api_integration_campaigns.updated_at < 7.days.ago || client_api_integration_campaigns.data.blank?

            client_api_integration_campaigns.data.presence || []
          end
        end
      end
    end
  end
end
