# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/visits.rb
module Integrations
  module SuccessWare
    module V202311
      module Visits
        # call Successware API for a visit
        # sw_client.visit()
        #   (req) successware_visit_id: (String)
        def visit(successware_visit_id = nil)
          reset_attributes
          @result = {}

          if successware_visit_id.blank?
            @message = 'Successware visit ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                visit(id: "#{successware_visit_id}") {
                  id
                  title
                  startAt
                  endAt
                  visitStatus
                  isComplete
                  client {
                    id
                    isCompany
                  }
                  job {
                    id
                  }
                  assignedUsers {
                    nodes {
                      id
                    }
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Visits.visit',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :visit) : nil) || {}
        end

        # call successware API for visits
        # sw_client.visits
        #   (req) successware_job_id: (String)
        def visits(successware_job_id)
          reset_attributes
          @result = []

          if successware_job_id.blank?
            @message = 'Successware job ID is required.'
            return @result
          end

          visits = []
          cursor   = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  job(
                    id: "#{successware_job_id}"
                  ) {
                    visits(
                      first: 100,
                      after: "#{cursor}",
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
                }
              GRAPHQL
            }

            successware_request(
              body:,
              error_message_prepend: 'Integrations::SuccessWare::V202311::Visits.visits',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            visits += @result.dig(:data, :job, :visits, :nodes) || []
            break unless @result.dig(:data, :job, :visits, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :job, :visits, :nodes).present?

            cursor = @result.dig(:data, :job, :visits, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = visits.compact_blank
        end
      end
    end
  end
end
