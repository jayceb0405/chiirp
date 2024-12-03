# frozen_string_literal: true

# app/lib/integrations/job_ber/v20220915/users.rb
module Integrations
  module JobBer
    module V20220915
      module Users
        # call Jobber API for a user
        # jb_client.user()
        #   (req) jobber_user_id: (String)
        def user(jobber_user_id = nil)
          reset_attributes
          @result = {}

          if jobber_user_id.blank?
            @message = 'Jobber user ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query SampleQuery {
                user(id: "#{jobber_user_id}") {
                  id
                  name {
                    full
                  }
                  email {
                    raw
                  }
                  phone {
                    friendly
                    raw
                  }
                  status
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::jobber::V20220915::Users.user',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :user) : nil) || {}
        end

        # call jobber API for users
        # jb_client.users
        def users
          reset_attributes
          @result = {}
          users   = []
          cursor  = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  users(
                    first: 100,
                    after: "#{cursor}",
                    filter: { status: ACTIVATED }
                  ) {
                    nodes {
                      id
                      name {
                        full
                      }
                      email {
                        raw
                      }
                      phone {
                        friendly
                        raw
                      }
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
              error_message_prepend: 'Integrations::jobber::V20220915::Users.users',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            users += @result.dig(:data, :users, :nodes) || []
            break unless @result.dig(:data, :users, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :users, :nodes).present?

            cursor = @result.dig(:data, :users, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = users.compact_blank
        end
      end
    end
  end
end
