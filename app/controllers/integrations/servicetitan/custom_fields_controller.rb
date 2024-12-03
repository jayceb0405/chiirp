# frozen_string_literal: true

# app/controllers/integrations/servicetitan/custom_fields_controller.rb
module Integrations
  module Servicetitan
    class CustomFieldsController < Servicetitan::IntegrationsController
      # (GET) edit Custom Field assignments
      # /integrations/servicetitan/custom_fields/edit
      # edit_integrations_servicetitan_custom_fields_path
      # edit_integrations_servicetitan_custom_fields_url
      def edit
        render partial: 'integrations/servicetitan/custom_fields/js/show', locals: { cards: %w[edit] }
      end

      # (PUT/PATCH) save Custom Field assignments
      # /integrations/servicetitan/custom_fields
      # integrations_servicetitan_custom_fields_path
      # integrations_servicetitan_custom_fields_url
      def update
        if params.include?(:custom_field_assignments)
          @client_api_integration.update(custom_field_assignments: params_custom_field_assignments)
          cards = %w[edit_custom_field_assignments]
        elsif params.include?(:booking_fields)
          @client_api_integration.update(booking_fields: params_booking_fields)
          cards = %w[edit_booking_field_assignments]
        else
          render partial: 'integrations/servicetitan/custom_fields/js/show', locals: { cards: %w[edit] }
          return
        end

        render partial: 'integrations/servicetitan/custom_fields/js/show', locals: { cards: }
      end

      private

      def params_booking_fields
        sanitized_params = params.permit(booking_fields: {}).dig(:booking_fields)

        sanitized_params.each do |key, values|
          sanitized_params[key][:order]                  = values.dig(:order).to_i
          sanitized_params[key][:client_custom_field_id] = values.dig(:client_custom_field_id).to_i
        end

        sanitized_params
      end

      def params_custom_field_assignments
        sanitized_params = params.require(:custom_field_assignments).permit(:account_balance, :completion_date, :customer_type, :estimate_total, :ext_tech_name, :ext_tech_phone, :job_address, :job_city, :job_number, :job_state, :job_total, :job_zip)

        sanitized_params.each do |key, value|
          sanitized_params[key] = value.to_i
        end

        sanitized_params
      end
    end
  end
end
