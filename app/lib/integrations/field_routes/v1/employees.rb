# frozen_string_literal: true

# app/lib/integrations/field_routes/v1/employees.rb
module Integrations
  module FieldRoutes
    module V1
      module Employees
        def employee_ids
          reset_attributes
          @result = {}

          fieldroutes_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldRoutes::V1::Employees.employee_ids',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{api_url}/employee/search"
          )

          @result = (@result.is_a?(Hash) ? @result : nil) || {}
        end

        def employees(employee_ids)
          reset_attributes
          @result = {}

          if employee_ids.blank? || !employee_ids.is_a?(Array)
            @message = 'FieldRoutes employee_ids must be an array of integers'
            return @result
          end

          params = { employeeIDs: employee_ids }

          fieldroutes_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldRoutes::V1::Employees.employees',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   "#{api_url}/employee/get"
          )

          @result = (@result.is_a?(Hash) ? @result : [])
        end
      end
    end
  end
end
