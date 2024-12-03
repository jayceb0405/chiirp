# frozen_string_literal: true

# app/lib/integrations/job_ber/v20220915/quotes.rb
module Integrations
  module JobBer
    module V20220915
      module Quotes
        # call Jobber API for a quote
        # jb_client.quote()
        #   (req) jobber_quote_id: (String)
        def quote(jobber_quote_id = nil)
          reset_attributes
          @result = {}

          if jobber_quote_id.blank?
            @message = 'Jobber quote ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                quote(id: "#{jobber_quote_id}") {
                  id
                  title
                  quoteNumber
                  quoteStatus
                  client {
                    id
                    isCompany
                  }
                  property {
                    id
                    address {
                      street1
                      street2
                      city
                      postalCode
                      province
                      country
                    }
                  }
                  amounts {
                    total
                  }
                  lineItems {
                    nodes {
                      id
                      description
                      totalPrice
                      linkedProductOrService {
                        id
                      }
                    }
                  }
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20220915::Quotes.quote',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :quote) : nil) || {}
        end

        # call Jobber API for quotes
        # jb_client.quotes
        #   (req) jobber_client_id: (String)
        def quotes(jobber_client_id = nil)
          reset_attributes
          @result = {}

          if jobber_client_id.blank?
            @message = 'Jobber client ID is required.'
            return @result
          end

          quotes = []
          cursor = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  quotes(
                    first: 100,
                    after: "#{cursor}",
                    filter: {clientId: "#{jobber_client_id}"}
                  ) {
                    nodes {
                      id
                    }
                    pageInfo {
                      endCursor
                      hasNextPage
                    }
                    totalCount
                  }
                }
              GRAPHQL
            }

            jobber_request(
              body:,
              error_message_prepend: 'Integrations::JobBer::V20220915::Quotes.quotes',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            quotes += @result.dig(:data, :quotes, :nodes) || []
            break unless @result.dig(:data, :quotes, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :quotes, :nodes).present?

            cursor = @result.dig(:data, :quotes, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = quotes.compact_blank
        end
      end
    end
  end
end
