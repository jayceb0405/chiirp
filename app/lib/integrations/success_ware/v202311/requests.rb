# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/requests.rb
module Integrations
  module SuccessWare
    module V202311
      module Requests
        # call Successware API for a request
        # sw_client.request()
        #   (req) successware_request_id: (String)
        def request(successware_request_id = nil)
          reset_attributes
          @result = {}

          if successware_request_id.blank?
            @message = 'Successware request ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                request(id: "#{successware_request_id}") {
                  id
                  title
                  client {
                    id
                    isCompany
                  }
                  companyName
                  contactName
                  createdAt
                  email
                  phone
                  source
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
                  requestStatus
                  source
                  jobs {
                    edges {
                      node {
                        id
                      }
                    }
                  }
                  updatedAt
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Requests.request',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :request) : nil) || {}
        end

        # call Successware API for requests
        # sw_client.requests
        #   (req) successware_client_id: (String)
        def requests(successware_client_id = nil)
          reset_attributes
          @result = {}

          if successware_client_id.blank?
            @message = 'Successware client ID is required.'
            return @result
          end

          requests = []
          cursor   = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  requests(
                    first: 100,
                    after: "#{cursor}",
                    filter: {clientId: "#{successware_client_id}"}
                  ) {
                    nodes {
                      id
                      title
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
              error_message_prepend: 'Integrations::SuccessWare::V202311::Requests.requests',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            requests += @result.dig(:data, :requests, :nodes) || []
            break unless @result.dig(:data, :requests, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :requests, :nodes).present?

            cursor = @result.dig(:data, :requests, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = requests.compact_blank
        end
      end
    end
  end
end
