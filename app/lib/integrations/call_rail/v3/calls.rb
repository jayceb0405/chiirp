# frozen_string_literal: true

# app/lib/integrations/call_rail/v3/calls.rb
# https://apidocs.callrail.com/
module Integrations
  module CallRail
    module V3
      # process various API calls to CallRail
      module Calls
        def call(call_id); end

        def calls
          page = 1
          per_page = 100
          callrail_request(
            body:                  nil,
            error_message_prepend: 'Integrations::CallRail::V3.Calls.calls',
            method:                'get',
            params:                {
              page:,
              per_page:
            },
            default_result:        {},
            url:                   "/a/#{@account_id}/calls.json"
          )[:calls]
        end
      end
    end
  end
end
