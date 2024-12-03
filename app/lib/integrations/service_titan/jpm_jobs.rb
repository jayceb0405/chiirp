# frozen_string_literal: true

# app/lib/integrations/service_titan/jpm_jobs.rb
module Integrations
  module ServiceTitan
    module JpmJobs
      # list reasons for cancelation
      # st_client.cancel_reasons
      def cancel_reasons
        reset_attributes
        @result = {}

        self.servicetitan_request(
          error_message_prepend: 'Integrations::ServiceTitan::JpmJobs.cancel_reasons',
          method:                'get',
          params:                { pageSize: @max_page_size, page: 1 },
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/job-cancel-reasons"
        )

        if @result.is_a?(Hash) && @result.dig(:data)
          @result = @result[:data]
        else
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
          @result  = []
        end
      end

      # cancel a job
      #   st_client.cancel_job(111, 222, 'They cancelled')
      def cancel_job(id, cancel_reason_id, memo)
        body = {
          reasonId: cancel_reason_id,
          memo:
        }

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::JpmJobs.create_job',
          method:                'put',
          params:                {},
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/jobs/#{id}/cancel"
        )

        if @result.is_a?(Hash)
          response = @result
        else
          response = 0
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result = response
      end

      # create a booking in ServiceTitan
      #   st_client.create_job()
      #     (opt) arrival_end:      (DateTime)
      #     (opt) arrival_start:    (DateTime)
      #     (req) business_unit_id: (Integer)
      #     (req) campaign_id:      (Integer)
      #     (req) customer_id:      (Integer)
      #     (opt) description:      (String)
      #     (req) end_time:         (DateTime)
      #     (req) ext_tech_id:      (Integer)
      #     (req) job_type_id:      (Integer)
      #     (req) location_id:      (Integer)
      #     (req) start_time:       (DateTime)
      #     (req) tag_names:        (Array)
      #     (opt) custom_fields:    (Hash),
      #   )
      def create_job(args = {})
        reset_attributes
        end_time         = args.dig(:end_time).respond_to?(:iso8601) ? args[:end_time].iso8601 : nil
        start_time       = args.dig(:start_time).respond_to?(:iso8601) ? args[:start_time].iso8601 : nil
        arrival_end      = args.dig(:arrival_end).respond_to?(:iso8601) ? args[:arrival_end].iso8601 : end_time
        arrival_start    = args.dig(:arrival_start).respond_to?(:iso8601) ? args[:arrival_start].iso8601 : start_time
        @result          = 0

        if args.dig(:business_unit_id).to_i.zero?
          @message = 'ServiceTitan Business Unit ID is required.'
          return @result
        elsif args.dig(:campaign_id).to_i.zero?
          @message = 'ServiceTitan Campaign ID is required.'
          return @result
        elsif args.dig(:customer_id).to_i.zero?
          @message = 'ServiceTitan Customer ID is required.'
          return @result
        elsif args.dig(:job_type_id).to_i.zero?
          @message = 'ServiceTitan Job Type ID is required.'
          return @result
        elsif args.dig(:location_id).to_i.zero?
          @message = 'ServiceTitan Location ID is required.'
          return @result
        elsif [args.dig(:tag_names) || []].flatten.blank?
          @message = 'Tag Names are required.'
          return @result
        elsif args.dig(:ext_tech_id).to_i.zero?
          @message = 'ServiceTitan Technician ID is required.'
          return @result
        elsif start_time.blank?
          @message = 'Start Time is required.'
          return @result
        elsif end_time.blank?
          @message = 'End Time is required.'
          return @result
        end

        custom_fields = []

        (args.dig(:custom_fields)&.deep_symbolize_keys || {}).each do |st_custom_field_id, values|
          custom_fields << {
            typeId: st_custom_field_id.to_i,
            value:  values[:value].to_s
          }
        end

        body = {
          businessUnitId: args[:business_unit_id].to_i,
          jobTypeId:      args[:job_type_id].to_i,
          campaignId:     args[:campaign_id].to_i,
          appointments:   [{
            start:              start_time,
            end:                end_time,
            technicianIds:      [args[:ext_tech_id].to_i],
            arrivalWindowStart: arrival_start,
            arrivalWindowEnd:   arrival_end
          }],
          customerId:     args[:customer_id].to_i,
          locationId:     args[:location_id].to_i,
          summary:        args.dig(:description).to_s.strip,
          tags:           args[:tag_names],
          customFields:   custom_fields,
          priority:       'Normal'
        }

        # https://developer.servicetitan.io/api-details/#api=tenant-jpm-v2&operation=Jobs_Create
        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::JpmJobs.create_job',
          method:                'post',
          params:                {},
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/jobs"
        )

        if @result.is_a?(Hash)
          response = @result.dig(:id).to_i
        else
          response = 0
          @success = false
          @message = "Unexpected response: #{@result.inspect}"

          JsonLog.info 'Integrations::ServiceTitan::JpmJobs.create_job', { success: @success, message: @message, result: @result, args:, faraday_result: @faraday_result }
        end

        @result = response
      end

      # call ServiceTitan API for a job
      # st_client.job()
      #   (req) job_id: (Integer)
      def job(job_id)
        reset_attributes
        @result = {}

        if job_id.to_i.zero?
          @message = 'ServiceTitan Job ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::JpmJobs.job',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/jobs/#{job_id}"
        )
      end

      # call ServiceTitan API for reasons a specific job was cancelled
      # st_client.job_cancel_reasons()
      #   (req) st_job_ids: (Integer)
      def job_cancel_reasons(st_job_ids)
        reset_attributes
        @result = {}

        if !st_job_ids.is_a?(Array) && st_job_ids.to_i.zero?
          @message = 'ServiceTitan Job ID is required.'
          return @result
        elsif st_job_ids.is_a?(Array) && st_job_ids.blank?
          @message = 'ServiceTitan Job IDs are required.'
          return @result
        end

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::JpmJobs.job_cancel_reasons',
          method:                'get',
          params:                { ids: [st_job_ids].flatten.map(&:to_s).join(',') },
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/jobs/cancel-reasons"
        )

        if @result.is_a?(Hash) && @result.dig(:data)
          @result = @result[:data]
        else
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
          @result  = []
        end
      end
      # example ServiceTitan job cancel reasons for a specific job
      # [
      #   {
      #     jobId:    0,
      #     reasonId: 0,
      #     name:     'string',
      #     text:     'string'
      #   }, ...
      # ]

      # call ServiceTitan API for a count of jobs for a customer
      # st_client.jobs_count(customer_id: Integer)
      # (req) customer_id:     (Integer)
      # (opt) competed_before: (Time)
      # (opt) completed_after: (Time)
      def jobs_count(args = {})
        reset_attributes
        @result = self.jobs(args.merge(count_only: true))
      end

      # call ServiceTitan API for jobs
      # st_client.jobs(customer_id: Integer)
      #   (opt) count_only:      (Boolean)
      #   (opt) customer_id:     (Integer)
      #   (opt) competed_before: (Time)
      #   (opt) completed_after: (Time)
      #   (opt) page:            (Integer)
      #   (opt) page_size:       (Integer)
      #   (opt) st_job_ids:      (Array of Integers / max 50)
      def jobs(args = {})
        reset_attributes
        @result  = []
        response = @result
        params   = {
          page:     [args.dig(:page).to_i, 1].max,
          pageSize: (args.dig(:page_size) || (args.dig(:count_only).to_bool ? 1 : @page_size)).to_i
        }
        params[:appointmentStartsBefore]         = args[:appointment_period_min].iso8601 if args.dig(:appointment_period_min).respond_to?(:iso8601)
        params[:appointmentStartsOnOrAfter]      = args[:appointment_period_max].iso8601 if args.dig(:appointment_period_max).respond_to?(:iso8601)
        params[:businessUnitId]                  = args[:business_unit_id].to_i if args.dig(:business_unit_id).to_i.positive?
        params[:campaignId]                      = args[:campaign_id].to_i if args.dig(:campaign_id).to_i.positive?
        params[:completedBefore]                 = args[:job_completed_period_min].iso8601 if args.dig(:job_completed_period_min).respond_to?(:iso8601)
        params[:completedOnOrAfter]              = args[:job_completed_period_max].iso8601 if args.dig(:job_completed_period_max).respond_to?(:iso8601)
        params[:createdBefore]                   = args[:job_created_period_min].iso8601 if args.dig(:job_created_period_min).respond_to?(:iso8601)
        params[:createdOnOrAfter]                = args[:job_created_period_max].iso8601 if args.dig(:job_created_period_max).respond_to?(:iso8601)
        params[:firstAppointmentStartsBefore]    = args[:first_appointment_period_min].iso8601 if args.dig(:first_appointment_period_min).respond_to?(:iso8601)
        params[:firstAppointmentStartsOnOrAfter] = args[:first_appointment_period_max].iso8601 if args.dig(:first_appointment_period_max).respond_to?(:iso8601)
        params[:ids]                             = args[:st_job_ids].map(&:to_s).join(',') if args.dig(:st_job_ids).is_a?(Array) && args[:st_job_ids].present?
        params[:modifiedBefore]                  = args[:job_modified_period_min].iso8601 if args.dig(:job_modified_period_min).respond_to?(:iso8601)
        params[:modifiedOnOrAfter]               = args[:job_modified_period_max].iso8601 if args.dig(:job_modified_period_max).respond_to?(:iso8601)
        params[:customerId]                      = args[:customer_id].to_i if args.dig(:customer_id).to_i.positive?
        params[:includeTotal]                    = args.dig(:count_only).to_bool
        params[:jobStatus]                       = args[:job_status].to_s if args.dig(:job_status).present?
        params[:jobTypeId]                       = args[:job_type_id].to_s if args.dig(:job_type_id).present?
        params[:locationId]                      = args[:location_id].to_i if args.dig(:location_id).to_i.positive?
        params[:soldById]                        = args[:sold_by_id].to_i if args.dig(:sold_by_id).to_i.positive?
        params[:technicianId]                    = args[:technician_id].to_i if args.dig(:technician_id).to_i.positive?

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::JpmJobs.jobs',
          method:                'get',
          params:,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_jpm}/#{api_version}/tenant/#{self.tenant_id}/jobs"
        )

        if @result.is_a?(Hash)
          response = if args.dig(:count_only).to_bool
                       @result.dig(:totalCount).to_i
                     else
                       @result.dig(:data) || []
                     end
        else
          response = args.dig(:count_only).to_bool ? 0 : []
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result = response
      end
      # example result
      # [
      #   {
      #     id:                     2430303,
      #     jobNumber:              '11061',
      #     projectId:              nil,
      #     customerId:             2388356,
      #     locationId:             2396438,
      #     jobStatus:              'Completed',
      #     completedOn:            '2010-12-03T16:00:00Z',
      #     businessUnitId:         1380032,
      #     jobTypeId:              1000002,
      #     priority:               'Normal',
      #     campaignId:             1000001,
      #     summary:                'NO HEAT ',
      #     customFields:           [],
      #     appointmentCount:       1,
      #     firstAppointmentId:     16280626,
      #     lastAppointmentId:      16280626,
      #     recallForId:            nil,
      #     warrantyId:             nil,
      #     jobGeneratedLeadSource: { jobId: nil, employeeId: nil },
      #     noCharge:               false,
      #     notificationsEnabled:   false,
      #     createdOn:              '2010-12-03T14:00:00Z',
      #     createdById:            0,
      #     modifiedOn:             '2017-07-31T22:54:24.22Z',
      #     tagTypeIds:             [],
      #     leadCallId:             nil,
      #     bookingId:              nil,
      #     soldById:               nil,
      #     externalData:           nil,
      #     customerPo:             nil
      #   }, ...
      # ]
    end
  end
end
