# frozen_string_literal: true

# app/lib/integrations/field_pulse/v1/job_status_workflow_statuses.rb
module Integrations
  module FieldPulse
    module V1
      module JobStatusWorkflowStatuses
        # call FieldPulse API for job status workflow statuses
        # fp_client.job_status_workflow_statuses
        def job_status_workflow_statuses
          reset_attributes
          @result = {}
          job_status_workflow_statuses = []
          page = 1

          loop do
            params = {
              limit: 100,
              page:
            }

            fieldpulse_request(
              body:                  nil,
              error_message_prepend: 'Integrations::FieldPulse::V1::JobStatusWorkflowStatuses.job_status_workflow_statuses',
              method:                'get',
              params:,
              default_result:        @result,
              url:                   'jobs/status-workflow-statuses'
            )

            job_status_workflow_statuses += @result.dig(:response) || []
            break if job_status_workflow_statuses.length >= @result.dig(:total_results).to_i || @result.dig(:error).to_bool

            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = job_status_workflow_statuses.compact_blank
        end
        # example fieldpulse_request result:
        # {
        #   error:         false,
        #   total_results: 3,
        #   response:      [
        #     {
        #       id:          920843,
        #       icon:        'xmark',
        #       name:        'Canceled',
        #       type:        'canceled',
        #       color:       '#d93c37',
        #       company_id:  114785,
        #       created_at:  '2024-09-12 19:31:11',
        #       deleted_at:  null,
        #       updated_at:  '2024-09-12 19:31:11',
        #       object_type: 'job'
        #     },
        #     {
        #       id:          920842,
        #       icon:        'check',
        #       name:        'Completed',
        #       type:        'completed',
        #       color:       '#9b9b9b',
        #       company_id:  114785,
        #       created_at:  '2024-09-12 19:31:11',
        #       deleted_at:  null,
        #       updated_at:  '2024-09-12 19:31:11',
        #       object_type: 'job'
        #     },
        #     {
        #       id:          920840,
        #       icon:        'spinner',
        #       name:        'In Progress',
        #       type:        'in_progress',
        #       color:       '#88cc40',
        #       company_id:  114785,
        #       created_at:  '2024-09-12 19:31:11',
        #       deleted_at:  null,
        #       updated_at:  '2024-09-12 19:31:11',
        #       object_type: 'job'
        #     }
        #   ]
        # }
      end
    end
  end
end
