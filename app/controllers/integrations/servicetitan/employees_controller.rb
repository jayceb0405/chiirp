# frozen_string_literal: true

# app/controllers/integrations/servicetitan/employees_controller.rb
module Integrations
  module Servicetitan
    class EmployeesController < Servicetitan::IntegrationsController
      # (GET) refresh ServiceTitan employees
      # /integrations/servicetitan/employees/refresh
      # integrations_servicetitan_employees_refresh_path
      # integrations_servicetitan_employees_refresh_url
      def refresh
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_technicians
      end

      # (GET) show ServiceTitan employees
      # /integrations/servicetitan/employees
      # integrations_servicetitan_employees_path
      # integrations_servicetitan_employees_url
      def show
        render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[employees] }
      end

      # (PUT/PATCH) save ServiceTitan employee links to internal Users
      # /integrations/servicetitan/employees
      # integrations_servicetitan_employees_path
      # integrations_servicetitan_employees_url
      def update
        @client_api_integration.update(employees: params_employees)

        render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[employees] }
      end

      private

      def params_employees
        params.permit(employees: {}).dig(:employees).to_unsafe_h.transform_values(&:to_i)
      end
    end
  end
end
