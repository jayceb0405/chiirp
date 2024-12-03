# frozen_string_literal: true

# app/lib/integrations/housecall_pro/jobs.rb
module Integrations
  module HousecallPro
    module Jobs
      # get a Housecall Pro customer job or jobs
      # hcp_client.job(job_id)
      def job(job_id)
        reset_attributes
        @result = {}

        if job_id.blank?
          @message = 'Housecall Pro Job ID is required.'
          return @result
        end

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Jobs.job',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/jobs/#{job_id}"
        )

        @result
      end

      # get Housecall Pro jobs
      # hcp_client.jobs()
      #   (req)
      def jobs(args = {})
        reset_attributes
        work_status = args.dig(:work_status).is_a?(Array) ? args.dig(:work_status).map(&:to_s) : [args.dig(:work_status).to_s].compact_blank # unscheduled, scheduled, in_progress, completed, canceled
        @result     = args.dig(:count_only).to_bool ? 0 : []

        params = {
          page:      args.dig(:count_only).to_bool ? 1 : args.dig(:page).to_i,
          page_size: args.dig(:count_only).to_bool ? 1 : (args.dig(:page_size) || 25).to_i
        }
        params[:customer_id]         = args[:customer_id].to_s if args.dig(:customer_id).to_s.present?
        params[:scheduled_end_max]   = args[:scheduled_end_max].utc.iso8601 if args.dig(:scheduled_end_max).is_a?(Time)
        params[:scheduled_end_min]   = args[:scheduled_end_min].utc.iso8601 if args.dig(:scheduled_end_min).is_a?(Time)
        params[:scheduled_start_max] = args[:scheduled_start_max].utc.iso8601 if args.dig(:scheduled_start_max).is_a?(Time)
        params[:scheduled_start_min] = args[:scheduled_start_min].utc.iso8601 if args.dig(:scheduled_start_min).is_a?(Time)
        params[:work_status]         = work_status if work_status.present?

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Jobs.jobs',
          method:                'get',
          params:,
          default_result:        @result,
          url:                   "#{base_url}/jobs"
        )

        @result = if @success && @result.is_a?(Hash)
                    if args.dig(:count_only).to_bool
                      @result.dig(:total_items).to_i
                    else
                      @result.dig(:jobs)
                    end
                  else
                    args.dig(:count_only).to_bool ? 0 : []
                  end
      end

      # get the total number of jobs for a Housecall Pro customer
      # hcp_client.customer_jobs_count(customer_id)
      #   (req) customer_id: (String)
      def jobs_count(args = {})
        @result = self.jobs(args.merge({ count_only: true }))
      end

      # call Housecall Pro API for job line items
      # hcp_client.job_line_items(job_id: String)
      def job_line_items(job_id)
        reset_attributes
        @result = []

        if job_id.blank?
          @message = 'Housecall Pro Job ID is required.'
          return @result
        end

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Jobs.job_line_items',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/jobs/#{job_id}/line_items"
        )

        @result = @success ? @result.dig(:data).map { |line_item| { id: line_item.dig(:service_item_id).to_s, name: line_item.dig(:name).to_s } } : []
      end
    end
  end
end
