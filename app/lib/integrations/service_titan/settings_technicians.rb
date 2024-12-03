# frozen_string_literal: true

# app/lib/integrations/service_titan/settings_technicians.rb
module Integrations
  module ServiceTitan
    module SettingsTechnicians
      # extract Technician data from ServiceTitan JobAssignments model
      # st_client.parse_ext_tech_id_from_job_assignments_model(job_assignment_model)
      #   (opt) job_assignment_model: (Hash) ServiceTitan JobAssignments model
      def parse_ext_tech_id_from_job_assignments_model(job_assignments_model)
        return 0 unless job_assignments_model.is_a?(Array)

        job_assignments_model.delete_if { |jam| !jam.is_a?(Hash) }.select { |jam| jam.dig(:active) }.max_by { |jam| jam.dig(:split) }&.dig(:technician, :id).to_i
      end

      # call ServiceTitan API for a technician
      # st_client.technicians()
      #   (req) technician_id: (Integer)
      def technician(technician_id)
        reset_attributes
        @result = {}

        if technician_id.to_i.zero?
          @message = 'Technician ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::SettingsTechnicians.technician',
          method:                'get',
          params:                {},
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_settings}/#{api_version}/tenant/#{self.tenant_id}/technicians/#{technician_id.to_i}"
        )

        @result = if @success && @result.is_a?(Hash)
                    @result
                  else
                    {}
                  end
      end

      # call ServiceTitan API for technicians
      # st_client.technicians
      #   (opt) active_only:      (Boolean / default: true)
      #   (opt) page_size:        (Integer / max: 5000)
      def technicians(args = {})
        reset_attributes
        response = []
        page     = (args.dig(:page) || 1).to_i - 1

        params = {
          pageSize: (args.dig(:page_size) || @max_page_size).to_i
        }
        params[:active] = args.dig(:active_only).is_a?(Boolean) ? args[:active_only] : true

        loop do
          params[:page] = page += 1

          self.servicetitan_request(
            body:                  {},
            error_message_prepend: 'Integrations::ServiceTitan::SettingsTechnicians.technicians',
            method:                'get',
            params:,
            default_result:        {},
            url:                   "#{base_url}/#{api_method_settings}/#{api_version}/tenant/#{self.tenant_id}/technicians"
          )

          if @success && @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore).to_bool
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
