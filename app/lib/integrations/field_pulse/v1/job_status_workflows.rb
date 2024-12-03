# frozen_string_literal: true

# app/lib/integrations/field_pulse/v1/job_status_workflows.rb
module Integrations
  module FieldPulse
    module V1
      module JobStatusWorkflows
        # call FieldPulse API for job status workflows
        # fp_client.job_status_workflows
        def job_status_workflows
          reset_attributes
          @result              = {}
          job_status_workflows = []
          page                 = 1

          loop do
            params = {
              limit: 100,
              page:
            }

            fieldpulse_request(
              body:                  nil,
              error_message_prepend: 'Integrations::FieldPulse::V1::JobStatusWorkflows.job_status_workflows',
              method:                'get',
              params:,
              default_result:        @result,
              url:                   'jobs/status-workflows'
            )

            job_status_workflows += @result.dig(:response) || []
            break if job_status_workflows.length >= @result.dig(:total_results).to_i || @result.dig(:error).to_bool

            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = job_status_workflows.compact_blank
        end
        # example fieldpulse_request result:
        # {
        #   error:         false,
        #   total_results: 3,
        #   response:      [
        #     {
        #       id:                173020,
        #       name:              'Default Workflow',
        #       statuses:          [
        #         {
        #           id:          920838,
        #           icon:        'sparkles',
        #           name:        'New',
        #           type:        'new',
        #           color:       '#0094D6',
        #           pivot:       {
        #             status_id:   920838,
        #             workflow_id: 173020
        #           },
        #           company_id:  114785,
        #           created_at:  '2024-09-12 19:31:11',
        #           deleted_at:  null,
        #           updated_at:  '2024-09-12 19:31:11',
        #           object_type: 'job'
        #         },
        #         {
        #           id:          920839,
        #           icon:        'route',
        #           name:        'On The Way',
        #           type:        'travel_time',
        #           color:       '#ba68c8',
        #           pivot:       {
        #             status_id:   920839,
        #             workflow_id: 173020
        #           },
        #           company_id:  114785,
        #           created_at:  '2024-09-12 19:31:11',
        #           deleted_at:  null,
        #           updated_at:  '2024-09-12 19:31:11',
        #           object_type: 'job'
        #         }
        #       ],
        #       is_active:         true,
        #       company_id:        114785,
        #       created_at:        '2024-09-12 19:31:11',
        #       deleted_at:        null,
        #       is_default:        true,
        #       status_ids:        [
        #         920838,
        #         920839,
        #         920840,
        #         920841,
        #         920842,
        #         920843
        #       ],
        #       updated_at:        '2024-09-12 19:31:11',
        #       object_type:       'job',
        #       default_status:    {
        #         id:                  920838,
        #         icon:                'sparkles',
        #         name:                'New',
        #         type:                'new',
        #         color:               '#0094D6',
        #         company_id:          114785,
        #         created_at:          '2024-09-12 19:31:11',
        #         deleted_at:          null,
        #         updated_at:          '2024-09-12 19:31:11',
        #         object_type:         'job',
        #         laravel_through_key: 173020
        #       },
        #       default_status_id: 920838
        #     }
        #   ]
        # }
      end
    end
  end
end
