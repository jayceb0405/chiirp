# frozen_string_literal: true

# app/controllers/integrations/jobber/v20220915/graphql_queries_controller.rb
# rubocop:disable all
module Integrations
  module Jobber
    module V20220915
      # sample data received from Housecall Pro
      class GraphqlQueriesController < Jobber::V20220915::IntegrationsController
        def account
          body = {
            query: <<-GRAPHQL.squish
              query SampleQuery {
                account {
                  id
                  name
                }
              }
            GRAPHQL
          }
        end

        def clients
          body = {
            query: <<-GRAPHQL.squish
              query ClientsQuery (
                $limit: Int,
                $cursor: String,
                $filter: ClientFilterAttributes,
              ) {
                clients(first: $limit, after: $cursor, filter: $filter) {
                  nodes {
                    id
                    name
                  }
                  pageInfo {
                    endCursor
                    hasNextPage
                  }
                }
              }
            GRAPHQL
          }
        end
      end
    end
  end
end
