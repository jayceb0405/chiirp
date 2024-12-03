# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/employees.rb
module Integration
  module Fieldroutes
    module V1
      module Customers
        def customer(customer_id)
          reset_attributes

          unless Integer(customer_id, exception: false).present?
            @message = 'Customer ID is required.'
            return @result
          end

          @result = customers([customer_id]).first
        end

        def customer_ids(filter = {})
          reset_attributes

          unless filter.is_a?(Hash)
            @message = 'Filter must be a Hash.'
            return @success
          end

          @fr_client.customer_ids(filter)
          update_attributes_from_client

          @result = @fr_client.result.dig(:customerIDs).to_a
        end

        def customers(customer_ids)
          reset_attributes

          unless customer_ids.is_a?(Array)
            @message = 'Customer IDs must be an Array.'
            return @success
          end

          @fr_client.customers(customer_ids)
          update_attributes_from_client

          @result = @fr_client.result.dig(:customers).to_a
        end
      end
    end
  end
end
