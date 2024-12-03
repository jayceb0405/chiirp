# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/quotes.rb
module Integrations
  module SuccessWare
    module V202311
      module Quotes
        # call Successware API for a quote
        # sw_client.quote()
        #   (req) successware_quote_id: (String)
        def quote(successware_quote_id = nil)
          reset_attributes
          @result = {}

          if successware_quote_id.blank?
            @message = 'Successware quote ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                quote(id: "#{successware_quote_id}") {
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

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Quotes.quote',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :quote) : nil) || {}
        end

        # call Successware API for quotes
        # sw_client.quotes
        #   (req) successware_client_id: (String)
        def quotes(successware_client_id = nil)
          reset_attributes
          @result = {}

          if successware_client_id.blank?
            @message = 'Successware client ID is required.'
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
                    filter: {clientId: "#{successware_client_id}"}
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

            successware_request(
              body:,
              error_message_prepend: 'Integrations::SuccessWare::V202311::Quotes.quotes',
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
