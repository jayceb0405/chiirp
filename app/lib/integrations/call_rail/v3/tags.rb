# frozen_string_literal: true

# app/lib/integrations/call_rail/v3/tags.rb
# https://apidocs.callrail.com/
module Integrations
  module CallRail
    module V3
      # process various API calls to CallRail
      module Tags
        # all tags in the account
        def all_available_tags
          page = 1
          per_page = 100
          out = []

          loop do
            res = callrail_request(
              body:                  nil,
              error_message_prepend: 'Integrations::CallRail::V3.Tags.all_available_tags',
              method:                'get',
              params:                {
                page:,
                per_page:,
                status:   'enabled'
              },
              default_result:        {},
              url:                   "/a/#{@account_id}/tags.json"
            )
            res[:tags].each do |tag|
              out << tag
            end
            break if res[:total_pages] == page

            page += 1
          end

          out
        end

        # limited by current company
        def available_tags
          all_available_tags.keep_if { |tag| tag[:tag_level] == 'account' || (tag[:tag_level] == 'company' && tag[:company_id] == @company_id) }
        end
      end
    end
  end
end
