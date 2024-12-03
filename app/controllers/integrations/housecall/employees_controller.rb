# frozen_string_literal: true

# app/controllers/integrations/housecall/employees_controller.rb
module Integrations
  module Housecall
    class EmployeesController < Housecall::IntegrationsController
      # (GET) show Housecall employees
      # /integrations/housecall/employees
      # integrations_housecall_employees_path
      # integrations_housecall_employees_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[employees] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PUT/PATCH) save Housecall Pro employee links to internal Users
      # /integrations/housecall/employees
      # integrations_housecall_employees_path
      # integrations_housecall_employees_url
      def update
        @client_api_integration.update(employees: params_employees)

        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[employees] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      private

      def params_employees
        params.permit(employees: {}).dig(:employees).to_unsafe_h.transform_values(&:to_i)
      end
    end
  end
end
