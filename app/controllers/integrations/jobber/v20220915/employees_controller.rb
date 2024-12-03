# frozen_string_literal: true

# app/controllers/integrations/jobber/v20220915/employees_controller.rb
module Integrations
  module Jobber
    module V20220915
      # support for connecting Jobber employees with internal Users
      class EmployeesController < Jobber::V20220915::IntegrationsController
        # (GET) show Jobber employees
        # /integrations/jobber/v20220915/employees
        # integrations_jobber_v20220915_employees_path
        # integrations_jobber_v20220915_employees_url
        def show
          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[employees] }
        end

        # (PUT/PATCH) save Jobber employee links to internal Users
        # /integrations/jobber/v20220915/employees
        # integrations_jobber_v20220915_employees_path
        # integrations_jobber_v20220915_employees_url
        def update
          @client_api_integration.update(employees: params_employees)

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[employees] }
        end

        private

        def params_employees
          params.permit(employees: {}).dig(:employees).to_unsafe_h.transform_values(&:to_i)
        end
      end
    end
  end
end
