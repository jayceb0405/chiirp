# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/jobs/job_types.rb
module Integration
  module Servicetitan
    module V2
      module Jobs
        module JobTypes
          # call ServiceTitan API to update ClientApiIntegration.job_types
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_job_types
          def refresh_job_types
            return unless valid_credentials?

            client_api_integration_job_types.update(data: @st_client.job_types, updated_at: Time.current)
          end

          def job_types_last_updated
            client_api_integration_job_types_data.present? ? client_api_integration_job_types.updated_at : nil
          end

          # return all job_types data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).job_types
          #   (opt) raw: (Boolean / default: false)
          def job_types(args = {})
            if args.dig(:raw)
              client_api_integration_job_types_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_job_types_data.map(&:deep_symbolize_keys)&.map { |jt| [jt[:name], jt[:id]] }&.sort || []
            end
          end

          private

          def client_api_integration_job_types
            @client_api_integration_job_types ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'job_types')
          end

          def client_api_integration_job_types_data
            refresh_job_types if client_api_integration_job_types.updated_at < 7.days.ago || client_api_integration_job_types.data.blank?

            client_api_integration_job_types.data.presence || []
          end
        end
      end
    end
  end
end
