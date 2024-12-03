# frozen_string_literal: true

# app/lib/integrations/job_ber/v20231115/products.rb
module Integrations
  module JobBer
    module V20231115
      module Products
        # call Jobber API for a product
        # jb_client.product()
        #   (req) jobber_product_id: (String)
        def product(jobber_product_id = nil)
          reset_attributes
          @result = {}

          if jobber_product_id.blank?
            @message = 'jobber product ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query SampleQuery {
                productOrService(id: "#{jobber_product_id}") {
                  id
                  name
                  description
                  category
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20231115::Products.products',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :product) : nil) || {}
        end

        # call jobber API for products
        # jb_client.products
        def products
          reset_attributes
          @result  = {}
          products = []
          cursor   = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  productOrServices(
                    first: 100,
                    after: "#{cursor}"
                  ) {
                    nodes {
                      id
                      name
                      description
                      category
                      visible
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
              error_message_prepend: 'Integrations::JobBer::V20231115::Products.products',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            products += @result.dig(:data, :productOrServices, :nodes) || []
            break unless @result.dig(:data, :productOrServices, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :productOrServices, :nodes).present?

            cursor = @result.dig(:data, :productOrServices, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = products.compact_blank.select { |p| p[:visible] }
        end
      end
    end
  end
end
