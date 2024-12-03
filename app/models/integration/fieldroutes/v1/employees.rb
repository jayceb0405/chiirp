# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/employees.rb
module Integration
  module Fieldroutes
    module V1
      module Employees
        EMPLOYEE_TYPES = {
          '0' => 'Office Staff',
          '1' => 'Technician',
          '2' => 'Sales Rep'
        }.freeze

        # call FieldRoutes API to update ClientApiIntegration.employees
        # Integration::Fieldroutes::V1::Base.new(client_api_integration).refresh_employees
        def refresh_employees
          return unless valid_credentials?

          client_api_integration_employees.update(data: fieldroutes_employees, updated_at: Time.current)
        end

        def employees_last_updated
          client_api_integration_employees_data.present? ? client_api_integration_employees.updated_at : nil
        end

        # return a specific employee's data
        # Integration::Fieldroutes::V1::Base.new(client_api_integration).employee()
        #   (req) fr_employee_id: (Integer)
        def employee(fr_employee_id)
          return [] if Integer(fr_employee_id, exception: false).blank?

          (client_api_integration_employees_data.find { |e| e['employeeID'] == fr_employee_id.to_s }.presence || {}).deep_symbolize_keys
        end

        # return all employees data
        # Integration::Fieldroutes::V1::Base.new(client_api_integration).employees
        def employees(_args = {})
          client_api_integration_employees_data.map(&:deep_symbolize_keys)
        end

        private

        def client_api_integration_employees
          @client_api_integration_employees ||= @client.client_api_integrations.find_or_create_by(target: 'fieldroutes', name: 'employees')
        end

        def client_api_integration_employees_data
          refresh_employees if client_api_integration_employees.updated_at < 7.days.ago || client_api_integration_employees.data.blank?

          client_api_integration_employees.data.presence || []
        end

        def fieldroutes_employee_ids
          @fr_client.employee_ids
          update_attributes_from_client

          if @success && @result.dig(:employeeIDs).is_a?(Array)
            @result[:employeeIDs]
          else
            []
          end
        end

        def fieldroutes_employees
          employees = []

          fieldroutes_employee_ids.in_groups_of(1000, false).each do |employee_ids|
            new_employees = @fr_client.employees(employee_ids)

            employees += new_employees[:employees] if @success && new_employees.dig(:employees).is_a?(Array)
          end

          employees
        end
      end
    end
  end
end
