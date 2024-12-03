# frozen_string_literal: true

# app/models/Integration/fieldpulse/v1/job_status_workflows.rb
module Integration
  module Fieldpulse
    module V1
      module JobStatusWorkflows
        # call FieldPulse API to update ClientApiIntegration.job_status_workflows
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).refresh_job_status_workflows
        def refresh_job_status_workflows
          return unless valid_credentials?

          client_api_integration_job_status_workflows.update(data: @fp_client.job_status_workflows, updated_at: Time.current)
        end

        def job_status_workflows_last_updated
          client_api_integration_job_status_workflows_data.present? ? client_api_integration_job_status_workflows.updated_at : nil
        end

        # return a specific job status workflow's data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).job_status_workflow()
        #   (req) fp_job_status_workflow_id: (Integer)
        #   (opt) raw:                       (Boolean / default: false)
        def job_status_workflow(fp_job_status_workflow_id, args = {})
          return [] if fp_job_status_workflow_id.to_i.zero?

          if (job_status_workflow = client_api_integration_job_status_workflows_data.find { |t| t['id'] == fp_job_status_workflow_id })

            if args.dig(:raw).to_bool
              job_status_workflow.deep_symbolize_keys
            else
              {
                id:   job_status_workflow.dig('id').to_i,
                name: job_status_workflow.dig('name')&.to_s
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
        #   (req) fp_job_status_workflow_id: (Integer)
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def job_status_workflow_statuses(fp_job_status_workflow_id, args = {})
          return [] if fp_job_status_workflow_id.to_i.zero?

          response = client_api_integration_job_status_workflows_data.find { |s| s.dig('id') == fp_job_status_workflow_id.to_i } || {}

          if args.dig(:for_select).to_bool
            response.dig('statuses')&.map { |t| [t.dig('name').to_s, t.dig('id').to_i] }&.sort
          elsif args.dig(:raw).to_bool
            response.dig('statuses')&.map(&:deep_symbolize_keys)
          else
            response.dig('statuses')&.map { |t| { id: t.dig('id'), name: t.dig('name') } }&.sort_by { |t| t[:name] }
          end
        end

        # return all job_status_workflows data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).job_status_workflows()
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def job_status_workflows(args = {})
          response = client_api_integration_job_status_workflows_data

          if args.dig(:for_select).to_bool
            response.map { |t| [t.dig('name').to_s, t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), name: t.dig('name') } }&.sort_by { |t| t[:name] }
          end
        end

        private

        def client_api_integration_job_status_workflows
          @client_api_integration_job_status_workflows ||= @client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: 'job_status_workflows')
        end

        def client_api_integration_job_status_workflows_data
          refresh_job_status_workflows if client_api_integration_job_status_workflows.updated_at < 7.days.ago || client_api_integration_job_status_workflows.data.blank?

          client_api_integration_job_status_workflows.data.presence || []
        end
      end
    end
  end
end
