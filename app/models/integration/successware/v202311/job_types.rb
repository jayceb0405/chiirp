# frozen_string_literal: true

# app/models/Integration/successware/v2/job_types.rb
module Integration
  module Successware
    module V202311
      module JobTypes
        # call Successware API to update ClientApiIntegration.job_types
        # Integration::Successware::V202311::Base.new(client_api_integration).refresh_job_types
        def refresh_job_types
          return unless valid_credentials?

          client_api_integration_job_types.update(data: @sw_client.job_types, updated_at: Time.current)
        end

        def job_types_last_updated
          client_api_integration_job_types_data.present? ? client_api_integration_job_types.updated_at : nil
        end

        # return all job_types data
        # Integration::Successware::V202311::Base.new(client_api_integration).job_types
        #   (opt) raw: (Boolean / default: false)
        #   (opt) grouped: (Boolean / default: false)
        def job_types(args = {})
          if args.dig(:raw)
            client_api_integration_job_types_data.map(&:deep_symbolize_keys)
          elsif args.dig(:grouped)
            response = {}
            client_api_integration_job_types_data.map(&:deep_symbolize_keys)&.map { |jt| response[jt[:jobClass]] = (response[jt[:jobClass]] || []) << [jt[:description], jt[:code]] }&.sort || []

            response
          else
            client_api_integration_job_types_data.map(&:deep_symbolize_keys)&.map { |jt| [jt[:description], jt[:code]] }&.sort || []
          end
        end

        private

        def client_api_integration_job_types
          @client_api_integration_job_types ||= @client.client_api_integrations.find_or_create_by(target: 'successware', name: 'job_types')
        end

        def client_api_integration_job_types_data
          refresh_job_types if client_api_integration_job_types.updated_at < 7.days.ago || client_api_integration_job_types.data.blank?

          client_api_integration_job_types.data.presence || []
        end
      end
    end
  end
end
