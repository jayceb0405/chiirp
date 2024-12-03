# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/reports/categories.rb
module Integration
  module Servicetitan
    module V2
      module Reports
        module Categories
          # call ServiceTitan API to update ClientApiIntegration.report_categories
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_report_categories
          def refresh_report_categories
            return unless valid_credentials?

            client_api_integration_report_categories.update(data: @st_client.report_categories, updated_at: Time.current)
          end

          def report_categories_last_updated
            client_api_integration_report_categories_data.present? ? client_api_integration_report_categories.updated_at : nil
          end

          # return all report_categories data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).report_categories
          #   (opt) raw: (Boolean / default: false)
          def report_categories(args = {})
            if args.dig(:raw)
              client_api_integration_report_categories_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_report_categories_data.map(&:deep_symbolize_keys)&.map { |c| [c[:name], c[:id]] }&.sort || []
            end
          end

          private

          def client_api_integration_report_categories
            @client_api_integration_report_categories ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'report_categories')
          end

          def client_api_integration_report_categories_data
            refresh_report_categories if client_api_integration_report_categories.updated_at < 7.days.ago || client_api_integration_report_categories.data.blank?

            client_api_integration_report_categories.data.presence || []
          end
        end
      end
    end
  end
end
