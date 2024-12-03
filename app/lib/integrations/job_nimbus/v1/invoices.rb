# frozen_string_literal: true

# app/lib/integrations/job_nimbus/v1/invoices.rb
module Integrations
  module JobNimbus
    module V1
      module Invoices
        # parse/normalize Invoice data from webhook
        def parse_invoice_from_webhook(args = {})
          if args.dig(:type).to_s == 'invoice'
            {
              id:     args.dig(:jnid).to_s,
              number: args.dig(:number).to_s,
              status: args.dig(:status_name).to_s,
              type:   args.dig(:type).to_s,
              notes:  args.dig(:internal_note).to_s
            }
          else
            {}
          end
        end
      end
    end
  end
end
