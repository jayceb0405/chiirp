# frozen_string_literal: true

# app/lib/integrations/job_nimbus/v1/jobs.rb
module Integrations
  module JobNimbus
    module V1
      module Jobs
        # jn_client.job(String)
        def job(jnid = '')
          reset_attributes
          @result = {}

          if jnid.blank?
            @message = 'JobNimbus job ID is required.'
            return @result
          end

          jobnimbus_request(
            body:                  nil,
            error_message_prepend: 'Integrations::JobNimbus::V1::Base.job',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/jobs/#{jnid}"
          )
        end

        # parse/normalize Job data from webhook
        def parse_job_from_webhook(args = {})
          if args.dig(:type).to_s == 'job'
            {
              id:          args.dig(:jnid).to_s,
              date_start:  args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
              date_end:    args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
              description: args.dig(:description).to_s,
              number:      args.dig(:number).to_s,
              status:      args.dig(:status_name).to_s,
              tags:        args.dig(:tags).to_s,
              type:        args.dig(:type).to_s
            }
          else
            {}
          end
        end
      end
    end
  end
end
