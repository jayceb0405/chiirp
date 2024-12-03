# frozen_string_literal: true

# app/controllers/integrations/servicemonster/employees_controller.rb
module Integrations
  module Servicemonster
    # support for connecting ServiceMonster employees with internal Users
    class EmployeesController < Servicemonster::IntegrationsController
      # (GET) show ServiceMonster employees
      # /integrations/servicemonster/employees
      # integrations_servicemonster_employees_path
      # integrations_servicemonster_employees_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[employees] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (PUT/PATCH) save ServiceMonster employee links to internal Users
      # /integrations/servicemonster/employees
      # integrations_servicemonster_employees_path
      # integrations_servicemonster_employees_url
      def update
        @client_api_integration.update(employees: params_employees)

        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[employees] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      private

      def params_employees
        params.permit(employees: {}).dig(:employees).to_unsafe_h.transform_values(&:to_i)
      end
    end
  end
end
