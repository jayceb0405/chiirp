# frozen_string_literal: true

# app/models/Integration/fieldpulse/v1/job_status_workflow_statuses.rb
module Integration
  module Fieldpulse
    module V1
      module JobStatusWorkflowStatuses
        # call FieldPulse API to update ClientApiIntegration.job_status_workflow_statuses
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).refresh_job_status_workflow_statuses
        def refresh_job_status_workflow_statuses
          return unless valid_credentials?

          client_api_integration_job_status_workflow_statuses.update(data: @fp_client.job_status_workflow_statuses, updated_at: Time.current)
        end

        def job_status_workflow_statuses_last_updated
          client_api_integration_job_status_workflow_statuses_data.present? ? client_api_integration_job_status_workflow_statuses.updated_at : nil
        end

        # return a specific job status workflow status's data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).job_status_workflow_status()
        #   (req) fp_job_status_workflow_status_id: (Integer)
        #   (opt) raw:                              (Boolean / default: false)
        def job_status_workflow_status(fp_job_status_workflow_status_id, args = {})
          return [] if fp_job_status_workflow_status_id.to_i.zero?

          if (job_status_workflow_status = client_api_integration_job_status_workflow_statuses_data.find { |t| t['id'] == fp_job_status_workflow_status_id })

            if args.dig(:raw).to_bool
              job_status_workflow_status.deep_symbolize_keys
            else
              {
                id:   job_status_workflow_status.dig('id').to_i,
                name: job_status_workflow_status.dig('name')&.to_s
              }
            end
          elsif args.dig(:raw).to_bool
            {}
          else
            {
              id:   0,
              name: ''
            }
          end
        end

        # return all job_status_workflow_statuses data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).job_status_workflow_statuses()
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def job_status_workflow_statuses(args = {})
          response = client_api_integration_job_status_workflow_statuses_data

          if args.dig(:for_select).to_bool
            response.map { |t| [t.dig('name').to_s, t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), name: t.dig('name') } }&.sort_by { |t| t[:name] }
          end
        end

        private

        def client_api_integration_job_status_workflow_statuses
          @client_api_integration_job_status_workflow_statuses ||= @client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: 'job_status_workflow_statuses')
        end

        def client_api_integration_job_status_workflow_statuses_data
          refresh_job_status_workflow_statuses if client_api_integration_job_status_workflow_statuses.updated_at < 7.days.ago || client_api_integration_job_status_workflow_statuses.data.blank?

          client_api_integration_job_status_workflow_statuses.data.presence || []
        end
      end
    end
  end
end
