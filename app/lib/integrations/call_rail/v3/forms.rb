# frozen_string_literal: true

# app/lib/integrations/call_rail/v3/forms.rb
# https://apidocs.callrail.com/
module Integrations
  module CallRail
    module V3
      # process various API forms to CallRail
      module Forms
        def form_submissions(company_id)
          page = 1
          per_page = 100
          out = []

          loop do
            res = callrail_request(
              body:                  nil,
              error_message_prepend: 'Integrations::CallRail::V3.Forms.form_submissions',
              method:                'get',
              params:                {
                fields:     'form_name',
                date_range: 'recent',
                company_id:,
                per_page:,
                page:
              },
              default_result:        {},
              url:                   "/a/#{account_id}/form_submissions.json"
            )

            res&.dig(:form_submissions)&.each do |form_submission|
              out << form_submission
            end

            break if res.nil? || res.blank? || res.dig(:total_pages) == page

            page += 1
          end

          out
        end

        def form_submission(company_id, id)
          page = 1
          per_page = 100
          out = nil

          loop do
            res = callrail_request(
              body:                  nil,
              error_message_prepend: 'Integrations::CallRail::V3.Forms.form_submission',
              method:                'get',
              params:                {
                fields:     'form_name',
                date_range: 'recent',
                sorting:    'submitted_at',
                company_id:,
                per_page:,
                page:
              },
              default_result:        {},
              url:                   "/a/#{account_id}/form_submissions.json"
            )

            res&.dig(:form_submissions)&.each do |form_submission|
              return form_submission if form_submission[:id] == id
            end

            break if res.nil? || res.blank? || res.dig(:total_pages) == page

            page += 1
          end

          out
        end
      end
    end
  end
end
