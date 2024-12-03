# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/employees.rb
module Integration
  module Servicetitan
    module V2
      module Employees
        # call ServiceTitan API to update ClientApiIntegration.employees
        # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_employees
        def refresh_employees
          return unless valid_credentials?

          client_api_integration_employees.update(data: @st_client.employees, updated_at: Time.current)
        end

        def employees_last_updated
          client_api_integration_employees_data.present? ? client_api_integration_employees.updated_at : nil
        end

        # return a specific employee's data
        # Integration::Servicetitan::V2::Base.new(client_api_integration).employee()
        #   (req) st_employee_id: (Integer)
        def employee(st_employee_id)
          return [] if st_employee_id.to_i.zero?

          client_api_integration_employees_data.find { |e| e['id'] == st_employee_id }.presence || {}
        end

        # return all employees data
        # Integration::Servicetitan::V2::Base.new(client_api_integration).employees
        def employees(_args = {})
          client_api_integration_employees_data
        end

        private

        def client_api_integration_employees
          @client_api_integration_employees ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'employees')
        end

        def client_api_integration_employees_data
          refresh_employees if client_api_integration_employees.updated_at < 7.days.ago || client_api_integration_employees.data.blank?

          client_api_integration_employees.data.presence || []
        end
      end
    end
  end
end
