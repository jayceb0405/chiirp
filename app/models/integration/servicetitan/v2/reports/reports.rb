# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/reports/reports.rb
module Integration
  module Servicetitan
    module V2
      module Reports
        module Reports
          # call ServiceTitan API to update ClientApiIntegration.reports
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_reports
          #   (req) st_report_category_id: (String)
          def refresh_reports(args = {})
            return if args.dig(:st_report_category_id).blank?
            return unless valid_credentials?

            client_api_integration_reports.data[args.dig(:st_report_category_id)] = { updated_at: Time.current, reports: @st_client.reports(st_report_category_id: args.dig(:st_report_category_id)) }
            client_api_integration_reports.save
          end

          def reports_last_updated
            client_api_integration_reports_data.present? ? client_api_integration_reports.updated_at : nil
          end

          # return all reports data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).reports
          #   (req) st_report_category_id: (String)
          def reports(args = {})
            return [] if args.dig(:st_report_category_id).blank?

            client_api_integration_reports_data(st_report_category_id: args.dig(:st_report_category_id)).map(&:deep_symbolize_keys)
          end

          private

          def client_api_integration_reports
            @client_api_integration_reports ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'reports')
          end

          #   (req) st_report_category_id: (String)
          def client_api_integration_reports_data(args = {})
            return [] if args.dig(:st_report_category_id).blank?

            refresh_reports(st_report_category_id: args.dig(:st_report_category_id)) if client_api_integration_reports.data.dig(args.dig(:st_report_category_id), 'reports').blank? || client_api_integration_reports.data.dig(args.dig(:st_report_category_id), 'updated_at') < 7.days.ago

            client_api_integration_reports.data.dig(args.dig(:st_report_category_id), 'reports').presence || []
          end
        end
      end
    end
  end
end
