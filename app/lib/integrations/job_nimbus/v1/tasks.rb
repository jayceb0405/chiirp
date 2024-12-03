# frozen_string_literal: true

# app/lib/integrations/job_nimbus/v1/tasks.rb
module Integrations
  module JobNimbus
    module V1
      module Tasks
        # parse/normalize Task data from webhook
        def parse_task_from_webhook(args = {})
          if args.dig(:type).to_s == 'task'
            {
              id:         args.dig(:jnid).to_s,
              number:     args.dig(:number).to_s,
              title:      args.dig(:title).to_s,
              type:       args.dig(:record_type_name).to_s,
              date_start: args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
              date_end:   args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
              completed:  args.dig(:is_completed).to_bool
            }
          else
            {}
          end
        end
      end
    end
  end
end
