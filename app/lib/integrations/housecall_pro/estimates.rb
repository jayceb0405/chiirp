# frozen_string_literal: true

# app/lib/integrations/housecall_pro/estimates.rb
module Integrations
  module HousecallPro
    module Estimates
      # get a Housecall Pro customer estimate
      # hcp_client.estimate()
      #   (req) estimate_id: (String)
      def estimate(estimate_id)
        reset_attributes
        @result = {}

        if estimate_id.blank?
          @message = 'Housecall Pro Estimate ID is required.'
          return @result
        end

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Estimates.estimate',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/estimates/#{estimate_id}"
        )

        @result
      end

      # get Housecall Pro estimates
      # hcp_client.estimates()
      #   (opt) count_only:          (Boolean)
      #   (opt) customer_id:         (Integer)
      #   (opt) page:                (Integer)
      #   (opt) page_size:           (Integer)
      #   (opt) scheduled_end_max:   (Time)
      #   (opt) scheduled_end_min:   (Time)
      #   (opt) scheduled_start_max: (Time)
      #   (opt) scheduled_start_min: (Time)
      #   (opt) work_statuses:       (Array or String)
      def estimates(args = {})
        reset_attributes
        work_statuses = args.dig(:work_statuses).is_a?(Array) ? args.dig(:work_statuses).map(&:to_s) : [args.dig(:work_statuses).to_s].compact_blank # unscheduled, scheduled, in_progress, completed, canceled
        @result       = args.dig(:count_only).to_bool ? 0 : []

        params = {
          page:      args.dig(:page).to_i,
          page_size: (args.dig(:page_size) || 25).to_i
        }
        params[:customer_id]         = args[:customer_id].to_s if args.dig(:customer_id).to_s.present?
        params[:scheduled_end_max]   = args[:scheduled_end_max].utc.iso8601 if args.dig(:scheduled_end_max).is_a?(Time)
        params[:scheduled_end_min]   = args[:scheduled_end_min].utc.iso8601 if args.dig(:scheduled_end_min).is_a?(Time)
        params[:scheduled_start_max] = args[:scheduled_start_max].utc.iso8601 if args.dig(:scheduled_start_max).is_a?(Time)
        params[:scheduled_start_min] = args[:scheduled_start_min].utc.iso8601 if args.dig(:scheduled_start_min).is_a?(Time)
        params[:work_status]         = work_statuses if work_statuses.present?

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Estimates.estimates',
          method:                'get',
          params:,
          default_result:        @result,
          url:                   "#{base_url}/estimates"
        )

        @result = if @success
                    if args.dig(:count_only).to_bool
                      @result.dig(:total_items).to_i
                    else
                      @result.dig(:estimates)
                    end
                  else
                    args.dig(:count_only).to_bool ? 0 : []
                  end
      end

      # get the total number of estimates for a Housecall Pro customer
      # hcp_client.customer_estimates_count()
      # passes all args to self.estimates
      def estimates_count(args = {})
        @result = self.estimates(args.merge({ count_only: true }))
      end
    end
  end
end
