# frozen_string_literal: true

# app/models/integration/fieldpulse/v1/customers.rb
module Integration
  module Fieldpulse
    module V1
      module Customers
        # retrieve a specific FieldPulse customer
        # fp_model.customer()
        #   (req) fp_customer_id: (Integer)
        def customer(**args)
          reset_attributes

          @fp_client.customer(args.dig(:fp_customer_id).to_i)
          update_attributes_from_client

          if @fp_client.success? && @fp_client.result.dig(:response).is_a?(Hash)
            @result = @fp_client.result.dig(:response)
          else
            @message = 'FieldPulse customer not found'
            @result  = {}
            @success = false
          end

          @result
        end

        # list FieldPulse customers
        # fp_model.customers()
        #   (opt) page:  (Integer / default: 1)
        #   (opt) search: (String / default: nil)
        def customers(**args)
          reset_attributes
          result = []
          page   = (args.dig(:page) || 1).to_i

          loop do
            @fp_client.customers(page:, search: args.dig(:search).presence)

            if @fp_client.success?
              break unless @fp_client.result.dig(:response).is_a?(Array) && @fp_client.result.dig(:response).present?

              result += @fp_client.result.dig(:response)

              break if args.dig(:page).to_i.positive?

              page += 1
            else
              result = []

              break
            end
          end

          update_attributes_from_client

          @result = result
        end
      end
    end
  end
end
