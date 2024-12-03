# frozen_string_literal: true

# app/lib/integrations/service_titan/jpm_job_types.rb
module Integrations
  module ServiceTitan
    module JpmJobTypes
      class JpmJobTypesError < StandardError; end

      # find ServiceTitan JobTypeModel in data and extract job_type data
      # st_client.extract_job_type_from_model(
      #   (req) model: (Hash)
      def extract_job_type_from_model(args = {})
        job_type_model = args.dig(:model, :type) || {}
        response       = { success: false, job_type: { id: '', name: '' }, error_message: 'Unable to locate job type data.' }

        if job_type_model.present? && (job_type_model.is_a?(ActionController::Parameters) || job_type_model.is_a?(Hash)) && job_type_model.include?(:id) && job_type_model.include?(:name)
          response[:success]         = true
          response[:job_type][:id]   = job_type_model[:id].to_s
          response[:job_type][:name] = job_type_model[:name].to_s
          response[:error_message]   = ''
        else
          error = JpmJobTypesError.new(response[:error_message])
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::ServiceTitan::JpmJobTypes.extract_job_type_from_model')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'info',
              error_code:  0
            )
            Appsignal.add_custom_data(
              job_type_model:,
              response:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        end

        response
      end

      # call ServiceTitan API for job types
      # st_client.job_types()
      #   (opt) active_only: (Boolean)
      #   (opt) page:        (Integer)
      #   (opt) page_size:   (Integer)
      def job_types(args = {})
        reset_attributes
        page     = 0
        @result  = {}
        response = []

        loop do
          page += 1

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::JpmJobTypes.job_types',
            method:                'get',
            params:                { active: args.dig(:active_only).nil? ? true : args[:active_only].to_bool, page:, pageSize: @max_page_size },
            default_result:        [],
            url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/job-types"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data)
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
