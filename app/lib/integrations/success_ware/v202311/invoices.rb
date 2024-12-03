# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/invoices.rb
module Integrations
  module SuccessWare
    module V202311
      module Invoices
        # call Successware API for an invoice
        # sw_client.invoice()
        #   (req) successware_invoice_id: (String)
        def invoice(successware_invoice_id = nil)
          reset_attributes
          @result = {}

          if successware_invoice_id.blank?
            @message = 'Successware invoice ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                invoice(id: "#{successware_invoice_id}") {
                  id
                  amounts {
                    total
                    paymentsTotal
                    invoiceBalance
                  }
                  dueDate
                  invoiceNet
                  invoiceNumber
                  invoiceStatus
                  subject
                  client {
                    id
                    isCompany
                  }
                  jobs {
                    edges {
                      node {
                        id
                      }
                    }
                  }
                  lineItems {
                    nodes {
                      id
                      description
                      totalPrice
                    }
                  }
                  properties {
                    nodes {
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
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Invoices.invoice',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :invoice) : nil) || {}
        end
        # example invoice
        # {
        #   :id=>"Z2lkOi8vSm9iYmVyL0ludm9pY2UvODI0MTQxMzM=",
        #   :dueDate=>"2023-11-15T05:00:00Z",
        #   :invoiceNet=>0,
        #   :invoiceNumber=>"1981",
        #   :invoiceStatus=>"paid",
        #   :subject=>"For Services Rendered",
        #   :lineItems=>{
        #     :nodes=>[
        #       {:id=>"Z2lkOi8vSm9iYmVyL0ludm9pY2VMaW5lSXRlbS8xODE1NzQ1Mzc=", :description=>"Window tracks and grooves are vacuumed out and wiped down with cleaning solution.", :totalPrice=>73.0},
        #       {:id=>"Z2lkOi8vSm9iYmVyL0ludm9pY2VMaW5lSXRlbS8xODE1NzQ1Mzg=", :description=>"WINDOW CLEANING\n\n• Exterior windows cleaned\n• Complimentary exterior screen dusting", :totalPrice=>930.0}
        #     ]
        #   },
        #   :properties=>{
        #     :nodes=>[
        #       {
        #         :id=>"Z2lkOi8vSm9iYmVyL1Byb3BlcnR5LzU1NDkzOTgx",
        #         :address=>{:street1=>"26580 Willowgreen Drive", :street2=>nil, :city=>"Franklin", :postalCode=>"48025", :province=>"Michigan", :country=>"United States"}
        #       }
        #     ]
        #   }
        # }

        # call Successware API for invoices
        # sw_client.invoices
        #   (req) successware_client_id: (String)
        def invoices(successware_client_id = nil)
          reset_attributes
          @result = []

          if successware_client_id.blank?
            @message = 'Successware client ID is required.'
            return @result
          end

          invoices = []
          cursor   = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  invoices(
                    first: 100,
                    after: "#{cursor}",
                    filter: { clientId: "#{successware_client_id}" }
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
              error_message_prepend: 'Integrations::SuccessWare::V202311::Invoices.invoices',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            invoices += @result.dig(:data, :invoices, :nodes) || []
            break unless @result.dig(:data, :invoices, :pageInfo, :hasNextPage).to_bool && @result.dig(:data, :invoices, :nodes).present?

            cursor = @result.dig(:data, :invoices, :pageInfo, :endCursor).to_s
            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = invoices.compact_blank
        end
      end
    end
  end
end
