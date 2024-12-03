# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/reports/results_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Reports
        class ResultsClientJob < ApplicationJob
          class ResultsClientJobError < StandardError; end

          # Integrations::Servicetitan::V2::Reports::ResultsClientJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Reports::ResultsClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_report_results_client').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) client_id: (Integer)
          #   (req) report:    (String)
          def perform(**args)
            super

            return unless args.dig(:client_id).to_i.positive? && args.dig(:report).is_a?(Hash) &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'servicetitan', name: '')) &&
                          (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                          (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials)) &&
                          client_api_integration.client.client_api_integrations.where(target: 'servicetitan', name: 'scheduled_reports').any?

            args[:report] = args[:report].deep_symbolize_keys

            st_client.report_results(category: args.dig(:report, :category_id), report_id: args.dig(:report, :st_report, :id).to_i, parameters: st_model.report_parameters_for_request(args.dig(:report)))

            unless st_client.success?
              raise(MaxReadRequestsPerHourException) if st_client.error.to_i == 429
              return if st_client.error.to_i == 404 # report not found

              error = ResultsClientJobError.new(st_client.message)
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integrations::Servicetitan::V2::Reports::ResultsClientJob.perform')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'info',
                  error_code:  st_client.error
                )
                Appsignal.add_custom_data(
                  result:    st_client.result,
                  st_client:,
                  success:   st_client.success?,
                  file:      __FILE__,
                  line:      __LINE__
                )
              end

              return
            end

            run_at = Time.current

            st_client.result.dig(:data).in_groups_of(Integration::Servicetitan::V2::Base.new.import_block_count, false).each do |result_block|
              Integrations::Servicetitan::V2::Reports::ResultsBlockJob.set(wait_until: run_at).perform_later(
                client_id: client_api_integration.client_id,
                report:    args[:report],
                result:    result_block,
                fields:    st_client.result.dig(:fields)
              )
              run_at += Integration::Servicetitan::V2::Base.new.import_block_count.seconds
            end
          end

          def max_attempts
            10
          end

          def reschedule_at(current_time, attempts)
            if @reschedule_secs.positive?
              current_time + @reschedule_secs.seconds
            else
              current_time + ProcessError::Backoff.full_jitter(base: 5, cap: 10, retries: attempts).minutes
            end
          end
        end
      end
    end
  end
end
