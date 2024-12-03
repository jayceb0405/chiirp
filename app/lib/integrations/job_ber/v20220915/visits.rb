# frozen_string_literal: true

# app/lib/integrations/job_ber/v20220915/visits.rb
module Integrations
  module JobBer
    module V20220915
      module Visits
        # call Jobber API for a visit
        # jb_client.visit()
        #   (req) jobber_visit_id: (String)
        def visit(jobber_visit_id = nil)
          reset_attributes
          @result = {}

          if jobber_visit_id.blank?
            @message = 'Jobber visit ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                visit(id: "#{jobber_visit_id}") {
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

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::jobber::V20220915::Visits.visit',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :visit) : nil) || {}
        end

        # call jobber API for visits
        # jb_client.visits
        #   (req) jobber_job_id: (String)
        def visits(jobber_job_id)
          reset_attributes
          @result = []

          if jobber_job_id.blank?
            @message = 'Jobber job ID is required.'
            return @result
          end

          visits = []
          cursor   = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  job(
                    id: "#{jobber_job_id}"
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

            jobber_request(
              body:,
              error_message_prepend: 'Integrations::jobber::V20220915::Visits.visits',
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
