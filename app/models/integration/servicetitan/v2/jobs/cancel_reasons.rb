# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/jobs/cancel_reasons.rb
module Integration
  module Servicetitan
    module V2
      module Jobs
        module CancelReasons
          # call ServiceTitan API to update ClientApiIntegration.job_cancel_reasons
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_job_cancel_reasons
          def refresh_job_cancel_reasons
            return unless valid_credentials?

            client_api_integration_job_cancel_reasons.update(data: @st_client.cancel_reasons, updated_at: Time.current)
          end

          def job_cancel_reasons_last_updated
            client_api_integration_job_cancel_reasons_data.present? ? client_api_integration_job_cancel_reasons.updated_at : nil
          end

          # return all job_cancel_reasons data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).job_cancel_reasons
          #   (opt) raw: (Boolean / default: false)
          def job_cancel_reasons(args = {})
            if args.dig(:raw)
              client_api_integration_job_cancel_reasons_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_job_cancel_reasons_data.map(&:deep_symbolize_keys)&.map { |jc| [jc[:name], jc[:id]] }&.sort || []
            end
          end

          private

          def client_api_integration_job_cancel_reasons
            @client_api_integration_job_cancel_reasons ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'job_cancel_reasons')
          end

          def client_api_integration_job_cancel_reasons_data
            refresh_job_cancel_reasons if client_api_integration_job_cancel_reasons.updated_at < 7.days.ago || client_api_integration_job_cancel_reasons.data.blank?

            client_api_integration_job_cancel_reasons.data.presence || []
          end
        end
      end
    end
  end
end
