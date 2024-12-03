# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/reports/results_all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Reports
        class ResultsAllClientsJob < ApplicationJob
          # schedule ServiceTitan reports for each Client (every hour on the hour)
          # Integrations::Servicetitan::V2::Reports::ResultsAllClientsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Reports::ResultsAllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_report_results_all_clients').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) report_occurrence: (Integer) ex: 1, 2, 3, 4, 5 (ie: first, second, third... day of month)
          #   (req) report_day:       (String)  ex: Mon, Tue, Wed, Thu, Fri, Sat, Sun
          #   (req) report_hour:      (Integer)
          def perform(**args)
            super

            return unless [1, 2, 3, 4, 5].include?(args.dig(:report_occurrence)) && args.dig(:report_day).is_a?(String) && %w[Mon Tue Wed Thu Fri Sat Sun].include?(args[:report_day].capitalize) && Integer(args.dig(:report_hour), exception: false).present?

            ClientApiIntegration.where(target: 'servicetitan', name: 'scheduled_reports')
                                .where('data @> ?', [{ schedule: { occurrence: [args.dig(:report_occurrence)] } }].to_json)
                                .where('data @> ?', [{ schedule: { days: [args[:report_day].capitalize] } }].to_json)
                                .where('data @> ?', [{ schedule: { hour: [args[:report_hour]] } }].to_json).find_each do |client_api_integration_scheduled_reports|
              client_api_integration_scheduled_reports.data.select { |r| r.dig('schedule', 'days')&.include?(args[:report_day].capitalize) && r.dig('schedule', 'hour').include?(args[:report_hour]) }.each do |report|
                Integrations::Servicetitan::V2::Reports::ResultsClientJob.perform_later(client_id: client_api_integration_scheduled_reports.client_id, report:)
              end
            end
          end
        end
      end
    end
  end
end
