# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/pricebook/categories.rb
module Integration
  module Servicetitan
    module V2
      module Pricebook
        module Categories
          # call ServiceTitan API to update ClientApiIntegration.pricebook_categories
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_pricebook_categories
          def refresh_pricebook_categories
            return unless valid_credentials?

            client_api_integration_pricebook_categories.update(data: @st_client.pb_categories, updated_at: Time.current)
          end

          def pricebook_categories_last_updated
            client_api_integration_pricebook_categories_data.present? ? client_api_integration_pricebook_categories.updated_at : nil
          end

          # return all pricebook_categories data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).pricebook_categories
          #   (opt) raw: (Boolean / default: false)
          def pricebook_categories(args = {})
            if args.dig(:raw)
              client_api_integration_pricebook_categories_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_pricebook_categories_data.map(&:deep_symbolize_keys)&.map { |c| [c[:name], c[:id]] } || []
            end
          end

          private

          def client_api_integration_pricebook_categories
            @client_api_integration_pricebook_categories ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'pricebook_categories')
          end

          def client_api_integration_pricebook_categories_data
            refresh_pricebook_categories if client_api_integration_pricebook_categories.updated_at < 7.days.ago || client_api_integration_pricebook_categories.data.blank?

            client_api_integration_pricebook_categories.data.presence || []
          end
        end
      end
    end
  end
end
