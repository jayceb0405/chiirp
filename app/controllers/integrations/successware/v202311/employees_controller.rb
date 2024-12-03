# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/employees_controller.rb
module Integrations
  module Successware
    module V202311
      # support for connecting Successware employees with internal Users
      class EmployeesController < Successware::IntegrationsController
        # (GET) show Successware employees
        # /integrations/successware/v202311/employees
        # integrations_successware_v202311_employees_path
        # integrations_successware_v202311_employees_url
        def show
          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[employees] }
        end

        # (PUT/PATCH) save Successware employee links to internal Users
        # /integrations/successware/v202311/employees
        # integrations_successware_v202311_employees_path
        # integrations_successware_v202311_employees_url
        def update
          @client_api_integration.update(employees: params_employees)

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[employees] }
        end

        private

        def params_employees
          params.permit(employees: {}).dig(:employees).to_unsafe_h.transform_values(&:to_i)
        end
      end
    end
  end
end
