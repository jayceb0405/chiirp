# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/graphql_queries_controller.rb
# rubocop:disable all
module Integrations
  module Successware
    module V202311
      # sample data received from Housecall Pro
      class GraphqlQueriesController < Successware::IntegrationsController
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
