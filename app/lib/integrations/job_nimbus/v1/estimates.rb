# frozen_string_literal: true

# app/lib/integrations/job_nimbus/v1/estimates.rb
module Integrations
  module JobNimbus
    module V1
      module Estimates
        # parse/normalize Estimate data from webhook
        def parse_estimate_from_webhook(args = {})
          if args.dig(:type).to_s == 'estimate'
            {
              id:         args.dig(:jnid).to_s,
              number:     args.dig(:number).to_s,
              status:     args.dig(:status_name).to_s,
              type:       args.dig(:type).to_s,
              date_start: args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
              date_end:   args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
              notes:      args.dig(:internal_note).to_s
            }
          else
            {}
          end
        end
      end
    end
  end
end
