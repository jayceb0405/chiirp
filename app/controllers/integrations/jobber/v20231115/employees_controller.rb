# frozen_string_literal: true

# app/controllers/integrations/jobber/v20231115/employees_controller.rb
module Integrations
  module Jobber
    module V20231115
      # support for connecting Jobber employees with internal Users
      class EmployeesController < Jobber::IntegrationsController
        # (GET) show Jobber employees
        # /integrations/jobber/v20231115/employees
        # integrations_jobber_v20231115_employees_path
        # integrations_jobber_v20231115_employees_url
        def show
          render partial: 'integrations/jobber/v20231115/js/show', locals: { cards: %w[employees] }
        end

        # (PUT/PATCH) save Jobber employee links to internal Users
        # /integrations/jobber/v20231115/employees
        # integrations_jobber_v20231115_employees_path
        # integrations_jobber_v20231115_employees_url
        def update
          @client_api_integration.update(employees: params_employees)

          render partial: 'integrations/jobber/v20231115/js/show', locals: { cards: %w[employees] }
        end

        private

        def params_employees
          params.permit(employees: {}).dig(:employees).to_unsafe_h.transform_values(&:to_i)
        end
      end
    end
  end
end
