# frozen_string_literal: true

# app/lib/integrations/call_rail/v3/accounts.rb
# https://apidocs.callrail.com/
module Integrations
  module CallRail
    module V3
      # process various API calls to CallRail
      module Accounts
        def accounts
          page = 1
          per_page = 100
          out = []

          loop do
            res = callrail_request(
              body:                  nil,
              error_message_prepend: 'Integrations::CallRail::V3.Accounts.accounts',
              method:                'get',
              params:                {
                page:,
                per_page:
              },
              default_result:        {},
              url:                   '/a.json'
            )
            res[:accounts].each do |account|
              out << account
            end
            break if res.nil? || res.blank? || res[:total_pages] == page

            page += 1
          end

          out
        end

        def all_companies
          out = Hash.new { |hash, key| hash[key] = [] }

          accounts.each do |account|
            companies_by_account(account[:id]).each do |company|
              out[account] << company
            end
          end

          out
        end

        def companies_by_account(account_id)
          return [] unless account_id

          page = 1
          per_page = 100
          out = []

          loop do
            res = callrail_request(
              body:                  nil,
              error_message_prepend: 'Integrations::CallRail::V3.Accounts.companies_by_account',
              method:                'get',
              params:                {
                page:,
                per_page:
              },
              default_result:        {},
              url:                   "/a/#{account_id}/companies.json"
            )
            res[:companies].each do |company|
              out << company
            end
            break if res.nil? || res.blank? || res[:total_pages] == page

            page += 1
          end

          out
        end

        def company_name_from_id(id)
          res = callrail_request(
            body:                  nil,
            error_message_prepend: 'Integrations::CallRail::V3.Accounts.company_name_from_id',
            method:                'get',
            params:                nil,
            default_result:        {},
            url:                   "/a/#{account_id}/companies/#{id}.json"
          )
          res[:name]
        end
      end
    end
  end
end
