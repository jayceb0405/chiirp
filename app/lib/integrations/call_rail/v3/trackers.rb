# frozen_string_literal: true

# app/lib/integrations/call_rail/v3/trackers.rb
# https://apidocs.callrail.com/
module Integrations
  module CallRail
    module V3
      # process various API calls to CallRail
      module Trackers
        def trackers(type: nil, status: 'active')
          page = 1
          out = []

          loop do
            res = callrail_request(
              body:                  nil,
              error_message_prepend: 'Integrations::CallRail::V3.Trackers.trackers',
              method:                'get',
              params:                {
                company_id: @company_id,
                type:,
                status:
              },
              default_result:        {},
              url:                   "/a/#{@account_id}/trackers.json"
            )
            res[:trackers].each do |tracker|
              out << tracker
            end
            break if res[:total_pages] == page

            page += 1
          end
          out
        end

        def tracking_phone_numbers(type: nil)
          trackers(type:).pluck(:tracking_numbers).flatten
        end

        def source_names
          trackers.pluck(:name)
        end
      end
    end
  end
end
