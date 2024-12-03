# frozen_string_literal: true

# app/presenters/integrations/servicetitan/custom_fields_presenter.rb
module Integrations
  module Servicetitan
    class CustomFieldsPresenter < BasePresenter
      def account_balance
        @client_api_integration.custom_field_assignments.dig('account_balance').to_i
      end

      def completion_date
        @client_api_integration.custom_field_assignments.dig('completion_date').to_i
      end

      def custom_field_currency_hash
        @client_api_integration.client.client_custom_fields.where(var_type: 'currency').order(:var_name).pluck(:var_name, :id)
      end

      def custom_field_date_hash
        @client_api_integration.client.client_custom_fields.where(var_type: 'date').order(:var_name).pluck(:var_name, :id)
      end

      def custom_field_number_hash
        @client_api_integration.client.client_custom_fields.where(var_type: 'numeric').order(:var_name).pluck(:var_name, :id)
      end

      def custom_field_string_hash
        @client_api_integration.client.client_custom_fields.where(var_type: 'string').order(:var_name).pluck(:var_name, :id)
      end

      def customer_custom_fields
        @client_api_integration.customer_custom_fields || {}
      end

      def customer_type
        @client_api_integration.custom_field_assignments.dig('customer_type').to_i
      end

      def estimate_total
        @client_api_integration.custom_field_assignments.dig('estimate_total').to_i
      end

      def ext_tech_name
        @client_api_integration.custom_field_assignments.dig('ext_tech_name').to_i
      end

      def ext_tech_phone
        @client_api_integration.custom_field_assignments.dig('ext_tech_phone').to_i
      end

      def job_address
        @client_api_integration.custom_field_assignments.dig('job_address').to_i
      end

      def job_city
        @client_api_integration.custom_field_assignments.dig('job_city').to_i
      end

      def job_number
        @client_api_integration.custom_field_assignments.dig('job_number').to_i
      end

      def job_state
        @client_api_integration.custom_field_assignments.dig('job_state').to_i
      end

      def job_total
        @client_api_integration.custom_field_assignments.dig('job_total').to_i
      end

      def job_zip
        @client_api_integration.custom_field_assignments.dig('job_zip').to_i
      end
    end
  end
end
