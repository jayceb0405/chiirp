# frozen_string_literal: true

# app/lib/integrations/job_ber/v20231115/requests.rb
module Integrations
  module JobBer
    module V20231115
      module Requests
        # call Jobber API for a request
        # jb_client.request()
        #   (req) jobber_request_id: (String)
        def request(jobber_request_id = nil)
          reset_attributes
          @result = {}

          if jobber_request_id.blank?
            @message = 'Jobber request ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                request(id: "#{jobber_request_id}") {
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

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20231115::Requests.request',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :request) : nil) || {}
        end

        # call Jobber API for requests
        # jb_client.requests
        #   (req) jobber_client_id: (String)
        def requests(jobber_client_id = nil)
          reset_attributes
          @result = {}

          if jobber_client_id.blank?
            @message = 'Jobber client ID is required.'
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
                    filter: {clientId: "#{jobber_client_id}"}
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

            jobber_request(
              body:,
              error_message_prepend: 'Integrations::JobBer::V20231115::Requests.requests',
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
