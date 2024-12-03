# frozen_string_literal: true

# app/lib/integrations/service_titan/memberships.rb
module Integrations
  module ServiceTitan
    module Memberships
      # call ServiceTitan API for customer membership
      # st_client.customer_membership()
      #   (req) st_membership_id: (Integer)
      def customer_membership(st_membership_id)
        reset_attributes
        @result = {}

        if st_membership_id.to_i.zero?
          @message = 'ServiceTitan Membership ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Memberships.customer_membership',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/memberships/#{st_membership_id.to_i}"
        )

        unless @result.is_a?(Hash)
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end
      # example customer membership
      # {
      #   :id=>1485757,
      #   :createdOn=>"2018-09-07T15:13:39.7234082Z",
      #   :createdById=>2180,
      #   :modifiedOn=>"2022-06-28T10:31:26.6221904Z",
      #   :followUpOn=>"0001-01-01T00:00:00Z",
      #   :cancellationDate=>nil,
      #   :from=>"2018-09-07T00:00:00Z",
      #   :nextScheduledBillDate=>nil,
      #   :to=>"2019-09-07T00:00:00Z",
      #   :billingFrequency=>"OneTime",                  (OneTime, Monthly, EveryOtherMonth, Quarterly, BiAnnual, Annual)
      #   :renewalBillingFrequency=>nil,                 (OneTime, Monthly, EveryOtherMonth, Quarterly, BiAnnual, Annual)
      #   :status=>"Deleted",                            (Active, Suspended, Expired, Canceled, Deleted)
      #   :followUpStatus=>"NotAttempted",               (NotAttempted, Unreachable, Contacted, Won, Dismissed)
      #   :active=>false,
      #   :initialDeferredRevenue=>0.0,
      #   :duration=>12,
      #   :renewalDuration=>nil,
      #   :businessUnitId=>272,
      #   :customerId=>11323841,
      #   :membershipTypeId=>10102828,
      #   :activatedById=>2180,
      #   :activatedFromId=>1485756,
      #   :billingTemplateId=>nil,
      #   :cancellationBalanceInvoiceId=>nil,
      #   :cancellationInvoiceId=>nil,
      #   :followUpCustomStatusId=>nil,
      #   :locationId=>11350415,
      #   :paymentMethodId=>nil,
      #   :paymentTypeId=>nil,
      #   :recurringLocationId=>11350415,
      #   :renewalMembershipTaskId=>10103498,
      #   :renewedById=>nil,
      #   :soldById=>2180,
      #   :customerPo=>nil,
      #   :importId=>nil,
      #   :memo=>nil
      # }

      # call ServiceTitan API for customer memberships
      # st_client.customer_memberships()
      #   (opt) active_only:          (Boolean) [true, false, any]
      #   (opt) billing_frequency:    (string)  [OneTime, Monthly, EveryOtherMonth, Quarterly, BiAnnual, Annual]
      #   (opt) count_only:           (Boolean)
      #   (opt) created_before:       (String)  RFC3339
      #   (opt) created_on_or_after:  (String)  RFC3339
      #   (opt) duration:             (Integer) Filters by membership duration (in months); use null for ongoing memberships
      #   (opt) modified_before:      (String)  RFC3339
      #   (opt) modified_on_or_after: (String)  RFC3339
      #   (opt) page:                 (Integer)
      #   (opt) page_size:            (Integer)
      #   (opt) st_customer_ids:      (Array)
      #   (opt) st_membership_id:     (Integer)
      #   (opt) status:               (String)  [Active, Suspended, Expired, Canceled, Deleted]
      def customer_memberships(args = {})
        reset_attributes
        @result  = []
        response = args.dig(:count_only).to_bool ? 0 : @result
        st_customer_ids_block_size = begin
          args.dig(:st_customer_ids)&.length.to_i / (args.dig(:st_customer_ids)&.join(',')&.length.to_i / 1900).to_i
        rescue StandardError
          0
        end
        params = {
          active:   (args.dig(:active_only).nil? ? 'any' : args[:active_only].to_bool).to_s,
          pageSize: args.dig(:count_only).to_bool ? 1 : (args.dig(:page_size) || @page_size).to_i
        }

        (0..(begin
          (args.dig(:st_customer_ids)&.length.to_f / st_customer_ids_block_size).finite? ? args.dig(:st_customer_ids)&.length.to_f / st_customer_ids_block_size : 1
        rescue StandardError
          1
        end.ceil - 1)).each do |st_customer_ids_block|
          page = (args.dig(:page) || 1).to_i - 1
          params[:billingFrequency]  = args[:billing_frequency].to_s if args.include?(:billing_frequency)
          params[:createdBefore]     = args[:created_before].rfc3339 if args.dig(:created_before).respond_to?(:rfc3339)
          params[:createdOnOrAfter]  = args[:created_on_or_after].rfc3339 if args.dig(:created_on_or_after).respond_to?(:rfc3339)
          params[:customerIds]       = args[:st_customer_ids][(st_customer_ids_block * st_customer_ids_block_size)..((st_customer_ids_block * st_customer_ids_block_size) + st_customer_ids_block_size - 1)].map(&:to_s).join(',') if args.include?(:st_customer_ids)
          params[:duration]          = args[:duration].to_i if args.dig(:duration)
          params[:ids]               = args[:st_membership_id].to_i if args.include?(:st_membership_id)
          params[:includeTotal]      = args.dig(:count_only).to_bool
          params[:modifiedBefore]    = args[:modified_before].rfc3339 if args.dig(:modified_before).respond_to?(:rfc3339)
          params[:modifiedOnOrAfter] = args[:modified_on_or_after].rfc3339 if args.dig(:modified_on_or_after).respond_to?(:rfc3339)
          params[:status]            = args[:status].to_s if args.include?(:status)

          loop do
            page += 1
            params[:page] = page

            self.servicetitan_request(
              body:                  nil,
              error_message_prepend: 'Integrations::ServiceTitan::Memberships.customer_memberships',
              method:                'get',
              params:,
              default_result:        [],
              url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/memberships"
            )

            if @result.is_a?(Hash)

              if args.dig(:count_only).to_bool
                response += @result.dig(:totalCount)
                break
              else
                response += @result.dig(:data) || []
                break if args.dig(:page).to_i.positive?
                break unless @result.dig(:hasMore).to_bool
              end
            else
              response = []
              @success = false
              @message = "Unexpected response: #{@result.inspect}"
              break
            end
          end
        end

        @result = response
      end
      # example ServiceTitan customer memberships
      # [
      #   {
      #     id:                           1485757,
      #     createdOn:                    '2018-09-07T15:13:39.7234082Z',
      #     createdById:                  2180,
      #     modifiedOn:                   '2022-06-28T10:31:26.6221904Z',
      #     followUpOn:                   '0001-01-01T00:00:00Z',
      #     cancellationDate:             nil,
      #     from:                         '2018-09-07T00:00:00Z',
      #     nextScheduledBillDate:        nil,
      #     to:                           '2019-09-07T00:00:00Z',
      #     billingFrequency:             'OneTime',                     (OneTime, Monthly, EveryOtherMonth, Quarterly, BiAnnual, Annual)
      #     renewalBillingFrequency:      nil,                           (OneTime, Monthly, EveryOtherMonth, Quarterly, BiAnnual, Annual)
      #     status:                       'Deleted',                     (Active, Suspended, Expired, Canceled, Deleted)
      #     followUpStatus:               'NotAttempted',                (NotAttempted, Unreachable, Contacted, Won, Dismissed)
      #     active:                       false,
      #     initialDeferredRevenue:       0.0,
      #     duration:                     12,
      #     renewalDuration:              nil,
      #     businessUnitId:               272,
      #     customerId:                   11323841,
      #     membershipTypeId:             10102828,
      #     activatedById:                2180,
      #     activatedFromId:              1485756,
      #     billingTemplateId:            nil,
      #     cancellationBalanceInvoiceId: nil,
      #     cancellationInvoiceId:        nil,
      #     followUpCustomStatusId:       nil,
      #     locationId:                   11350415,
      #     paymentMethodId:              nil,
      #     paymentTypeId:                nil,
      #     recurringLocationId:          11350415,
      #     renewalMembershipTaskId:      10103498,
      #     renewedById:                  nil,
      #     soldById:                     2180,
      #     customerPo:                   nil,
      #     importId:                     nil,
      #     memo:                         nil
      #   }, ...
      # ]

      # call ServiceTitan API for recurring services for a specific Membership
      # st_client.membership_recurring_service_events()
      #   (opt) created_before:       (String)  RFC3339
      #   (opt) created_on_or_after:  (String)  RFC3339
      #   (opt) include_total:        (Boolean)
      #   (opt) page:                 (Integer)
      #   (opt) page_size:            (Integer)
      #   (opt) st_job_id:            (Integer)
      #   (opt) st_location_id:       (Integer)
      #   (opt) st_event_ids:         (Array of Integers)
      #   (opt) status:               (String)   [NotAttempted, Unreachable, Contacted, Won, Dismissed]
      def membership_recurring_service_events(args = {})
        reset_attributes
        @result  = []
        page     = (args.dig(:page) || 1).to_i - 1
        response = @result

        loop do
          page += 1

          params = {
            page:,
            pageSize: (args.dig(:page_size) || @page_size).to_i
          }
          params[:createdBefore]     = args[:created_before].rfc3339 if args.dig(:created_before).respond_to?(:rfc3339)
          params[:createdOnOrAfter]  = args[:created_on_or_after].rfc3339 if args.dig(:created_on_or_after).respond_to?(:rfc3339)
          params[:ids]               = args[:st_event_ids].map { |e| e.to_s.to_i }.delete_if(&:zero?).join(', ') if args.dig(:st_event_ids).is_a?(Array)
          params[:includeTotal]      = args[:include_total].to_bool if args.include?(:include_total)
          params[:jobId]             = args[:st_job_id].to_i if args.include?(:st_job_id)
          params[:locationId]        = args[:st_location_id].to_i if args.include?(:st_location_id)
          params[:status]            = args[:status] if args.include?(:status)

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Memberships.membership_recurring_services',
            method:                'get',
            params:,
            default_result:        {},
            url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/recurring-service-events"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break if args.dig(:page).to_i.positive?
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
      # example recurring services events
      # [
      #   {
      #     :id=>21059930,
      #     :locationRecurringServiceId=>21038740,
      #     :locationRecurringServiceName=>"MCS Maintenance Visit ",
      #     :membershipId=>21038737,
      #     :membershipName=>"Monthly Monuments Club Savings Plan 2 Unit",
      #     :status=>"Dismissed",                                                (NotAttempted, Unreachable, Contacted, Won, Dismissed)
      #     :date=>"2018-09-13T00:00:00Z",
      #     :createdOn=>"2018-09-24T16:40:31.3446786Z",
      #     :createdById=>2305,
      #     :modifiedOn=>"2022-10-25T06:46:46.2533333Z"
      #   },...
      # ]

      # call ServiceTitan API for recurring services export
      # st_client.membership_recurring_service_events_export()
      #   (opt) start_at: (DateTime)
      def membership_recurring_service_events_export(args = {})
        reset_attributes
        @result  = []
        response = @result
        params   = {}
        # params[:from] = args[:start_at].strftime('%Y-%m-%d') if args.dig(:start_at).respond_to?(:strftime)

        loop do
          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Memberships.membership_recurring_services',
            method:                'get',
            params:,
            default_result:        {},
            url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/export/recurring-service-events"
          )

          if @result.is_a?(Hash)
            response += if args.dig(:start_at).respond_to?(:strftime)
                          (@result.dig(:data) || []).select { |r| Chronic.parse(r[:date]).respond_to?(:to_datetime) && Chronic.parse(r[:date]).to_datetime >= args[:start_at].beginning_of_day }
                        else
                          @result.dig(:data) || []
                        end

            break unless @result.dig(:hasMore).to_bool && @result.dig(:continueFrom).present?

            params[:from] = @result[:continueFrom]
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end
      # example recurring services events export
      # [
      #   {:active=>true,
      #     :id=>266148892,
      #     :locationRecurringServiceId=>266150200,
      #     :locationRecurringServiceName=>"HVAC Cooling Maintenance ACO",
      #     :membershipId=>266150174,
      #     :membershipName=>"ITL COMBO GOLD SHIELD MEMBERSHIP",
      #     :status=>"Won",
      #     :date=>"2024-06-01T00:00:00Z",
      #     :createdOn=>"2024-05-06T17:23:11.1173718Z",
      #     :jobId=>266140317,
      #     :createdById=>20002049,
      #     :modifiedOn=>"2024-05-06T17:24:28.1243111Z"},
      #   {:active=>false,
      #     :id=>225490826,
      #     :locationRecurringServiceId=>143987741,
      #     :locationRecurringServiceName=>"Oil Fired Water Boiler",
      #     :membershipId=>47537936,
      #     :membershipName=>"(1) PREMIER OIL SYSTEM HVAC GOLD SHIELD MEMBERSHIP",
      #     :status=>"NotAttempted",
      #     :date=>"2025-08-01T00:00:00Z",
      #     :createdOn=>"2024-01-22T15:19:58.8925482Z",
      #     :jobId=>nil,
      #     :createdById=>20001153,
      #     :modifiedOn=>"2024-05-06T17:38:29.2765974Z"},
      #   {:active=>true,
      #     :id=>266153502,
      #     :locationRecurringServiceId=>266152010,
      #     :locationRecurringServiceName=>"Gas Boiler & Mini Split with (5) Heads",
      #     :membershipId=>266151995,
      #     :membershipName=>"(1) BASE HVAC GOLD SHIELD MEMBERSHIP",
      #     :status=>"NotAttempted",
      #     :date=>"2025-02-01T00:00:00Z",
      #     :createdOn=>"2024-05-06T17:42:59.0849801Z",
      #     :jobId=>nil,
      #     :createdById=>903556,
      #     :modifiedOn=>"2024-05-06T17:42:59.0849801Z"},
      #   ...
      # ]

      # call ServiceTitan API for recurring services for a specific Membership
      # st_client.membership_recurring_services()
      #   (req) st_membership_ids:    (Array of Integers)
      #
      #   (opt) active_only:          (Boolean)
      #   (opt) created_before:       (String)  RFC3339
      #   (opt) created_on_or_after:  (String)  RFC3339
      #   (opt) include_total:        (Boolean)
      #   (opt) modified_before:      (String)  RFC3339
      #   (opt) modified_on_or_after: (String)  RFC3339
      #   (opt) page:                 (Integer)
      #   (opt) page_size:            (Integer)
      #   (opt) st_location_ids:      (Array of Integers)
      def membership_recurring_services(args = {})
        reset_attributes
        @result  = []
        page     = (args.dig(:page) || 1).to_i - 1
        response = @result

        if !args.dig(:st_membership_ids).is_a?(Array) || args.dig(:st_membership_ids).blank?
          @message = 'ServiceTitan Membership ID is required.'
          return @result
        end

        loop do
          page += 1

          params = {
            active:   (args.dig(:active_only).nil? ? 'any' : args[:active_only].to_bool).to_s,
            page:,
            pageSize: (args.dig(:page_size) || @page_size).to_i
          }
          params[:createdBefore]     = args[:created_before].rfc3339 if args.dig(:created_before).respond_to?(:rfc3339)
          params[:createdOnOrAfter]  = args[:created_on_or_after].rfc3339 if args.dig(:created_on_or_after).respond_to?(:rfc3339)
          params[:includeTotal]      = args[:include_total].to_bool if args.include?(:include_total)
          params[:locationIds]       = args[:st_location_ids].map { |e| e.to_s.to_i }.delete_if(&:zero?).join(', ') if args.dig(:st_location_ids)
          params[:membershipIds]     = args[:st_membership_ids].map { |e| e.to_s.to_i }.delete_if(&:zero?).join(', ')
          params[:modifiedBefore]    = args[:modified_before].rfc3339 if args.dig(:modified_before).respond_to?(:rfc3339)
          params[:modifiedOnOrAfter] = args[:modified_on_or_after].rfc3339 if args.dig(:modified_on_or_after).respond_to?(:rfc3339)

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Memberships.membership_recurring_services',
            method:                'get',
            params:,
            default_result:        {},
            url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/recurring-services"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break if args.dig(:page).to_i.positive?
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
      # example recurring services
      # {
      #   :id=>21038740,
      #   :name=>"MCS Maintenance Visit ",
      #   :active=>true,
      #   :createdOn=>"2018-09-13T21:28:51.3401001Z",
      #   :createdById=>649,
      #   :modifiedOn=>"2023-03-14T03:05:32.0272847Z",
      #   :importId=>nil,
      #   :membershipId=>21038737,
      #   :locationId=>11356225,
      #   :recurringServiceTypeId=>10104077,
      #   :durationType=>"Continuous",           (Continuous, NumberOfVisits)
      #   :durationLength=>2,
      #   :from=>"2018-09-13T00:00:00Z",
      #   :to=>nil,
      #   :memo=>nil,
      #   :invoiceTemplateId=>21038744,
      #   :invoiceTemplateForFollowingYearsId=>21059328,
      #   :firstVisitComplete=>false,
      #   :activatedFromId=>nil,
      #   :allocation=>100.0,
      #   :businessUnitId=>272,
      #   :jobTypeId=>1485399,
      #   :campaignId=>nil,
      #   :priority=>"Low",                      (Low, Normal, High, Urgent)
      #   :jobSummary=>nil,
      #   :recurrenceType=>"Monthly",            (Weekly, Monthly, Seasonal, Daily, NthWeekdayOfMonth)
      #   :recurrenceInterval=>6,
      #   :recurrenceMonths=>[],                 (January, February, March, April, May, June, July, August, September, October, November, December)
      #   :recurrenceDaysOfWeek=>[],             (Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday)
      #   :recurrenceWeek=>"None",               (None, First, Second, Third, Fourth, Last)
      #   :recurrenceDayOfNthWeek=>nil,
      #   :recurrenceDaysOfMonth=>[13],
      #   :jobStartTime=>nil,
      #   :estimatedPayrollCost=>nil
      # }

      # call ServiceTitan API for membership type
      # st_client.membership_type()
      #   (req) membership_type_id: (Integer)
      def membership_type(membership_type_id)
        reset_attributes
        @result = {}

        if membership_type_id.to_i.zero?
          @message = 'ServiceTitan Membership Type ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Memberships.membership_type',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/membership-types/#{membership_type_id}"
        )

        unless @result.is_a?(Hash)
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end
      # example membership type
      # {
      #   :id=>67358424,
      #   :createdOn=>"2022-07-05T18:51:37.7651649Z",
      #   :createdById=>2305,
      #   :modifiedOn=>"2022-07-05T18:59:53.4852425Z",
      #   :importId=>nil,
      #   :billingTemplateId=>67334620,
      #   :name=>"Quarterly Commercial Maintenance",
      #   :active=>true,
      #   :discountMode=>"Basic",                      (Basic, Units, Categories)
      #   :locationTarget=>"SingleLocation",           (AllLocations, SingleLocation)
      #   :revenueRecognitionMode=>"Deferred",         (PointOfSale, Deferred)
      #   :autoCalculateInvoiceTemplates=>true,
      #   :useMembershipPricingTable=>true,
      #   :showMembershipSavings=>true
      # }

      # call ServiceTitan API for membership type list
      # st_client.membership_types()
      #   (opt) active_only:          (Boolean / default: nil)
      #   (opt) billing_frequency:    (string)  [OneTime, Monthly, EveryOtherMonth, Quarterly, BiAnnual, Annual]
      #   (opt) created_before:       (String)  RFC3339
      #   (opt) created_on_or_after:  (String)  RFC3339
      #   (opt) duration:             (Integer) Filters by membership duration (in months); use null for ongoing memberships
      #   (opt) include_total:        (Boolean)
      #   (opt) modified_before:      (String)  RFC3339
      #   (opt) modified_on_or_after: (String)  RFC3339
      #   (opt) page:                 (Integer)
      #   (opt) page_size:            (Integer)
      #   (opt) st_membership_ids:    (Array of Integers)
      def membership_types(args = {})
        reset_attributes
        @result  = []
        page     = (args.dig(:page) || 1).to_i - 1
        response = @result

        loop do
          page += 1

          params = {
            active:   (args.dig(:active_only).nil? ? 'any' : args[:active_only].to_bool).to_s,
            page:,
            pageSize: (args.dig(:page_size) || @max_page_size).to_i
          }
          params[:billingFrequency]  = args[:billing_frequency].to_s if args.include?(:billing_frequency)
          params[:createdBefore]     = args[:created_before].rfc3339 if args.dig(:created_before).respond_to?(:rfc3339)
          params[:createdOnOrAfter]  = args[:created_on_or_after].rfc3339 if args.dig(:created_on_or_after).respond_to?(:rfc3339)
          params[:duration]          = args[:duration].to_i if args.dig(:duration)
          params[:ids]               = args[:st_membership_ids].join(', ') if args.dig(:st_membership_ids).is_a?(Array)
          params[:includeTotal]      = args[:include_total].to_bool if args.include?(:include_total)
          params[:modifiedBefore]    = args[:modified_before].rfc3339 if args.dig(:modified_before).respond_to?(:rfc3339)
          params[:modifiedOnOrAfter] = args[:modified_on_or_after].rfc3339 if args.dig(:modified_on_or_after).respond_to?(:rfc3339)
          params[:status]            = args[:status].to_s if args.include?(:status)

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Memberships.membership_types',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_memberships}/#{api_version}/tenant/#{self.tenant_id}/membership-types"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break if args.dig(:page).to_i.positive?
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
      # example membership_types
      # [
      #   {
      #     :id=>13953,
      #     :createdOn=>"2018-08-31T19:08:33.891442Z",
      #     :createdById=>2689,
      #     :modifiedOn=>"2018-08-31T19:09:10.0203096Z",
      #     :importId=>nil,
      #     :billingTemplateId=>nil,
      #     :name=>"Comp Membership",
      #     :active=>true,
      #     :discountMode=>"Basic",                  (Basic, Units, Categories)
      #     :locationTarget=>"SingleLocation",       (AllLocations, SingleLocation)
      #     :revenueRecognitionMode=>"Deferred",     (PointOfSale, Deferred)
      #     :autoCalculateInvoiceTemplates=>true,
      #     :useMembershipPricingTable=>false,
      #     :showMembershipSavings=>true
      #   },...
      # ]
    end
  end
end
