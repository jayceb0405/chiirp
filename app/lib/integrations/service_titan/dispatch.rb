# frozen_string_literal: true

# app/lib/integrations/service_titan/dispatch.rb
module Integrations
  module ServiceTitan
    module Dispatch
      # call ServiceTitan API for BusinessUnit/Technician availability
      # st_client.technician_availability()
      # st_client.technician_availability(business_unit_id: 125418913, job_type_id: 125244583, ext_tech_id: 254935944, start_time: Time.current)
      #   (req) business_unit_id: (Integer)
      #   (req) ext_tech_id:      (Integer)
      #   (req) job_type_id:      (Integer)
      #   (req) start_time:       (DateTime)
      #   (opt) end_time:         (DateTime)
      def technician_availability(args = {})
        reset_attributes
        @result = []

        if args.dig(:business_unit_id).to_i.zero?
          @message = 'ServiceTitan Business Unit ID required.'
          return @result
        elsif args.dig(:job_type_id).to_i.zero?
          @message = 'ServiceTitan Job Type ID required.'
          return @result
        elsif !args.dig(:start_time).respond_to?(:iso8601)
          @message = 'Start Time is required.'
          return @result
        end

        body = {
          businessUnitIds:        [args[:business_unit_id].to_i],
          jobTypeId:              args[:job_type_id].to_i,
          startsOnOrAfter:        args[:start_time].iso8601,
          endsOnOrBefore:         args.dig(:end_time).respond_to?(:iso8601) ? args[:end_time].iso8601 : (args[:start_time] + 30.days).iso8601,
          skillBasedAvailability: false
        }

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::Dispatch.technician_availability',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_dispatch}/#{api_version}/tenant/#{self.tenant_id}/capacity"
        )

        if @result.is_a?(Hash)
          status_options = %w[available true]
          response       = []

          (@result.dig(:availabilities) || []).each do |range|
            if args[:ext_tech_id].to_i.positive? && (technician = range.dig(:technicians).find { |t| t[:id] == args[:ext_tech_id].to_i })
              response << {
                from:         Chronic.parse(range.dig(:start)),
                to:           Chronic.parse(range.dig(:end)),
                availability: status_options.include?((technician&.dig(:status) || 'true').to_s.downcase)
              }
            elsif args[:ext_tech_id].to_i.zero?
              response << {
                from:         Chronic.parse(range.dig(:start)),
                to:           Chronic.parse(range.dig(:end)),
                availability: range.dig(:openAvailability).to_f.positive?
              }
            end
          end
        else
          response = []
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result = response
      end

      # reset credentials
      # reload!; st_model = Integration::Servicetitan::V2::Base.new(ClientApiIntegration.last); st_model.valid_credentials?

      # call ServiceTitan API for BusinessUnit and any requested Technician's availability
      # reload!; st_client = Integrations::ServiceTitan::Base.new(ClientApiIntegration.last.credentials); st_client.multi_technician_availability(business_unit_id: 125418913, job_type_id: 125244583, ext_tech_ids: [254935944, 235807035], start_time: Time.current)
      #   (req) business_unit_id: (Integer)
      #   (req) ext_tech_ids:     (Array)
      #   (req) job_type_id:      (Integer)
      #   (req) start_time:       (DateTime)
      #   (opt) end_time:         (DateTime)
      def multi_technician_availability(args = {})
        reset_attributes
        @result = []

        if args.dig(:business_unit_id).to_i.zero?
          @message = 'ServiceTitan Business Unit ID required.'
          return @result
        elsif !args.dig(:ext_tech_ids).respond_to?(:each)
          @message = 'ServiceTitan Technician ID array required.'
          return @result
        elsif args.dig(:job_type_id).to_i.zero?
          @message = 'ServiceTitan Job Type ID required.'
          return @result
        elsif !args.dig(:start_time).respond_to?(:iso8601)
          @message = 'Start Time is required.'
          return @result
        end

        body = {
          businessUnitIds:        [args[:business_unit_id].to_i],
          jobTypeId:              args[:job_type_id].to_i,
          startsOnOrAfter:        args[:start_time].iso8601,
          endsOnOrBefore:         args.dig(:end_time).respond_to?(:iso8601) ? args[:end_time].iso8601 : (args[:start_time] + 30.days).iso8601,
          skillBasedAvailability: false
        }

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::Dispatch.technician_availability',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_dispatch}/#{api_version}/tenant/#{self.tenant_id}/capacity"
        )

        if @result.is_a?(Hash)
          status_options = %w[available true]
          response       = []

          (@result.dig(:availabilities) || []).each do |range|
            next unless valid_time_slot(range, args[:days_of_month], args[:days_of_week], args[:hours_of_day])

            if (technician = range.dig(:technicians).find_all { |t| args[:ext_tech_ids].map(&:to_i).include?(t[:id]) }.sample)
              response << {
                from:         Chronic.parse(range.dig(:start)),
                to:           Chronic.parse(range.dig(:end)),
                name:         technician[:name],
                availability: status_options.include?(technician.dig(:status).to_s.downcase),
                ext_tech_id:  technician[:id]
              }
            end
          end
        else
          response = []
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result = response
      end

      private

      def valid_time_slot(range, days_of_month, days_of_week, hours_of_day)
        return true unless days_of_month || days_of_week || hours_of_day

        start_time = Chronic.parse(range.dig(:start))
        end_time = Chronic.parse(range.dig(:end))

        return false if days_of_month && !(days_of_month.include?(start_time.day) || days_of_month.include?(end_time.day))
        return false if days_of_week && !(days_of_week.include?(start_time.wday) || days_of_week.include?(end_time.wday))
        return false if hours_of_day && ((start_time.hour..end_time.hour).to_a && hours_of_day).none?

        true
      end
    end
  end
end
