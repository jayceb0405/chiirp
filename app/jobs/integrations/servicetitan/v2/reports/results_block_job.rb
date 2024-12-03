# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/reports/results_block_job.rb
module Integrations
  module Servicetitan
    module V2
      module Reports
        class ResultsBlockJob < ApplicationJob
          # Integrations::Servicetitan::V2::Reports::ResultsBlockJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Reports::ResultsBlockJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_report_results_block').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) client_id: (Integer)
          #   (req) fields:    (Array)
          #   (req) report:    (String)
          #   (req) result:    (Array)
          def perform(**args)
            super

            return unless args.dig(:client_id).to_i.positive? && args.dig(:fields).is_a?(Array) && args.dig(:report).is_a?(Hash) && args.dig(:result).is_a?(Array)

            run_at = Time.current

            args[:result].each do |contact|
              Integrations::Servicetitan::V2::Reports::ResultsContactJob.set(wait_until: run_at).perform_later(
                client_id: args[:client_id],
                report:    args[:report],
                result:    contact,
                fields:    args[:fields]
              )
              run_at += 5.seconds
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
