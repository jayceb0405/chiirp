# frozen_string_literal: true

# app/lib/integrations/service_titan/settings_employees.rb
module Integrations
  module ServiceTitan
    module SettingsEmployees
      # get a specific] ServiceTitan employee
      # st_client.employee(employee_id)
      def employee(employee_id)
        reset_attributes
        @result = {}

        if employee_id.blank?
          @message = 'ServiceTitan employee ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::SettingsEmployee.employee',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_settings}/#{api_version}/tenant/#{self.tenant_id}/employees/#{employee_id}"
        )
      end

      # get a list of ServiceTitan employees
      # st_client.employees
      def employees
        reset_attributes
        @result   = []
        response  = @result
        page      = 0

        loop do
          page += 1

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::SettingsEmployee.employees',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_method_settings}/#{api_version}/tenant/#{self.tenant_id}/employees?active=True&page=#{page}&pageSize=#{@page_size}"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end
    end
  end
end
