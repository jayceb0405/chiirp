# frozen_string_literal: true

# app/lib/integrations/job_ber/v20220915/jobs.rb
module Integrations
  module JobBer
    module V20220915
      module Jobs
        # call Jobber API for a job
        # jb_client.job()
        #   (req) jobber_job_id: (String)
        def job(jobber_job_id = nil)
          reset_attributes
          @result = {}

          if jobber_job_id.blank?
            @message = 'Jobber job ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query SampleQuery {
                job(id: "#{jobber_job_id}") {
                  id
                  title
                  jobNumber
                  jobType
                  jobStatus
                  client {
                    id
                    isCompany
                  }
                  arrivalWindow {
                    startAt
                    endAt
                    duration
                  }
                  completedAt
                  startAt
                  endAt
                  total
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
                  invoices {
                    nodes {
                      id
                      invoiceNumber
                    }
                  }
                  visitSchedule {
                    assignedTo {
                      nodes {
                        id
                      }
                    }
                  }
                  quote {
                    id
                  }
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20220915::Jobs.jobs',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :job) : nil) || {}
        end

        # call Jobber API for jobs
        # jb_client.jobs
        #   (req) jobber_client_id: (String)
        def jobs(jobber_client_id = nil)
          reset_attributes
          @result = []

          if jobber_client_id.blank?
            @message = 'Jobber client ID is required.'
            return @result
          end

          jobs   = []
          cursor = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  client(
                    id: "#{jobber_client_id}"
                  ) {
                    workObjects(
                      first: 100,
                      after: "#{cursor}",
                    ) {
                      nodes {
                        ... on Job {
                          id
                          title
                        }
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
              error_message_prepend: 'Integrations::JobBer::V20220915::Jobs.jobs',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            jobs += @result.dig(:data, :client, :workObjects, :nodes) || []
            break unless @result.dig(:data, :client, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :client, :nodes).present?

            cursor = @result.dig(:data, :client, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = jobs.compact_blank
        end
      end
    end
  end
end
