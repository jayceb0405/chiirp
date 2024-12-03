# frozen_string_literal: true

# app/lib/integrations/service_titan/estimates.rb
module Integrations
  module ServiceTitan
    module Estimates
      # call ServiceTitan API for a specific estimate
      # st_client.estimate()
      #   (req) estimate_id: (Integer)
      def estimate(estimate_id)
        reset_attributes
        @result = {}

        if estimate_id.to_i.zero?
          @message = 'ServiceTitan estimate id is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Estimates.estimate',
          method:                'get',
          params:                nil,
          default_result:        [],
          url:                   "#{base_url}/#{api_method_estimates}/#{api_version}/tenant/#{self.tenant_id}/estimates/#{estimate_id}"
        )

        @result = @result.is_a?(Hash) ? @result : {}
      end

      # call ServiceTitan API for a count of estimates
      # st_client.estimate_count
      #   (opt) active:         (Boolean)  defaults to true if job_id == 0
      #   (opt) created_at_max: (DateTime) defaults to Time.current unless job_id > 0
      #   (opt) created_at_min: (DateTime) defaults to 30.days.ago.beginning_of_day unless job_id > 0
      #   (opt) job_id:         (Integer)
      #   (opt) status:         (String)
      #   (opt) total_max:      (BigDecimal)
      #   (opt) total_min:      (BigDecimal)
      #   (opt) updated_at_max: (DateTime)
      #   (opt) updated_at_min: (DateTime)
      def estimate_count(args = {})
        reset_attributes
        @result = self.estimates(args.merge(count_only: true))
      end

      # call ServiceTitan API for estimates for a job
      # st_client.estimates()
      #   (opt) active:          (Boolean / default: true if job_id == 0)
      #   (opt) created_at_max:  (DateTime / default: Time.current unless job_id > 0)
      #   (opt) created_at_min:  (DateTime / default: 30.days.ago.beginning_of_day unless job_id > 0)
      #   (opt) job_id:          (Integer)
      #   (opt) page:            (Integer)
      #   (opt) page_size:       (Integer)
      #   (opt) status:          (String / default: nil) (open, sold, dismissed)
      #   (opt) st_estimate_ids: (Array of Integers / default: [] / max 50)
      #   (opt) total_max:       (BigDecimal / default: nil)
      #   (opt) total_min:       (BigDecimal / default: nil)
      #   (opt) updated_at_max:  (DateTime / default: nil)
      #   (opt) updated_at_min:  (DateTime / default: nil)
      def estimates(args = {})
        reset_attributes
        page     = (args.dig(:page) || 1).to_i - 1
        @result  = []
        response = @result

        loop do
          page  += 1
          params = {
            page:,
            pageSize: (args.dig(:page_size) || (args.dig(:count_only).to_bool ? 1 : @page_size)).to_i
          }
          params[:active]            = args.dig(:active).nil? ? true : args[:active].to_bool if args.dig(:job_id).to_i.zero?
          params[:createdBefore]     = args[:created_at_max].utc.rfc3339 if args.dig(:created_at_max).respond_to?(:rfc3339)
          params[:createdBefore]     = Time.current.rfc3339 if params.exclude?(:createdBefore) && args.dig(:job_id).to_i.zero? && args.dig(:st_estimate_ids).blank?
          params[:createdOnOrAfter]  = args[:created_at_min].utc.rfc3339 if args.dig(:created_at_min).respond_to?(:rfc3339)
          params[:createdOnOrAfter]  = 30.days.ago.beginning_of_day.rfc3339 if params.exclude?(:createdOnOrAfter) && args.dig(:job_id).to_i.zero? && args.dig(:st_estimate_ids).blank?
          params[:ids]               = args[:st_estimate_ids].map(&:to_i).join(',') if args.dig(:st_estimate_ids).is_a?(Array) && args.dig(:st_estimate_ids).present?
          params[:includeTotal]      = args.dig(:count_only).to_bool
          params[:jobId]             = args[:job_id].to_i if args.dig(:job_id).to_i.positive?
          params[:modifiedBefore]    = args[:updated_at_max].utc.rfc3339 if args.dig(:updated_at_max).respond_to?(:rfc3339)
          params[:modifiedOnOrAfter] = args[:updated_at_min].utc.rfc3339 if args.dig(:updated_at_min).respond_to?(:rfc3339)
          params[:status]            = args[:status].to_s if args.dig(:status).to_s.present?
          params[:totalGreater]      = args[:total_min].to_d if args.dig(:total_min).to_d.positive?
          params[:totalLess]         = args[:total_max].to_d if args.dig(:total_max).to_d.positive?

          self.servicetitan_request(
            body:                  {},
            error_message_prepend: 'Integrations::ServiceTitan::Estimates.estimates',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_estimates}/#{api_version}/tenant/#{self.tenant_id}/estimates"
          )

          if @result.is_a?(Hash)

            if args.dig(:count_only).to_bool
              response = @result.dig(:totalCount).to_i
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

        @result = response
      end
      # example ServiceTitan estimates response
      # [
      #   { id:               101909061,
      #     jobId:            101886381,
      #     projectId:        101886380,
      #     locationId:       101645511,
      #     customerId:       101645506,
      #     name:             '40’ liner ',
      #     jobNumber:        '101886381',
      #     status:           { value: 0, name: 'Open' },
      #     reviewStatus:     'None',
      #     summary:          "We were called to the home about a main sewer backing up into a basement toilet. Upon arrival after popping the toilet and relieving the clog we preformed a camera inspection of the line. We found 40’ of 4” cast iron that had several areas where holes were present in the pipe. We found several feet that was holding water due to the channeling in the bottom of the pipe from deterioration. There is also a sizable hole in the 90° fitting attaching to the toilet flange. To resolve this we will be rehabilitating this line from the toilet flange out to the trap located in the back of the home. To complete this we will be doing the following:\n\n- Wet out 3-4” flex liner with us sensitive epoxy \n- Haul in equipment and material \n- Pop toilet in basement bath \n- Descale and flush sewer \n- Invert 40’ liner down toilet flange out to trap \n- Invert calibration tube \n- Cure liner with blue uv light \n- Open any reinstatements \n- Camera inspect \n- Reset toilet \n- Clean up and haul out ",
      #     createdOn:        '2024-03-13T17:58:02.661Z',
      #     modifiedOn:       '2024-03-13T18:06:06.3220711Z',
      #     soldOn:           nil,
      #     soldBy:           nil,
      #     active:           true,
      #     items:            [{ id:               101908637,
      #                          sku:              { id:                       101356478,
      #                                              name:                     'Production Management',
      #                                              displayName:              'Production Management',
      #                                              type:                     'Service',
      #                                              soldHours:                0.0,
      #                                              generalLedgerAccountId:   16401630,
      #                                              generalLedgerAccountName: 'Revenue-40000',
      #                                              modifiedOn:               '2024-03-04T18:12:29.1558746Z' },
      #                          skuAccount:       'Revenue-40000',
      #                          description:      'Customer Loyalty Discount',
      #                          membershipTypeId: nil,
      #                          qty:              1.0,
      #                          unitRate:         -2000.0,
      #                          total:            -2000.0,
      #                          unitCost:         0.0,
      #                          totalCost:        0.0,
      #                          itemGroupName:    nil,
      #                          itemGroupRootId:  nil,
      #                          createdOn:        '2024-03-13T17:58:42.7334042Z',
      #                          modifiedOn:       '2024-03-13T17:58:42.8312925Z',
      #                          chargeable:       nil },
      #                        { id:               101909067,
      #                          sku:              { id:                       101354823,
      #                                              name:                     'PL100',
      #                                              displayName:              'Pipe Liner Rehabilitation',
      #                                              type:                     'Service',
      #                                              soldHours:                0.0,
      #                                              generalLedgerAccountId:   16400442,
      #                                              generalLedgerAccountName: 'Revenue',
      #                                              modifiedOn:               '2024-03-18T16:13:24.4468224Z' },
      #                          skuAccount:       'Revenue',
      #                          description:      'Descale and clean existing sewer line.<br>Wet and prep liner.<br>Invert liner into existing sewer line.<br>Invert calibration tube into sewer line.<br>Cure liner with UV cure system.<br>Record liner with camera.',
      #                          membershipTypeId: nil,
      #                          qty:              1.0,
      #                          unitRate:         16987.0,
      #                          total:            16987.0,
      #                          unitCost:         0.0,
      #                          totalCost:        0.0,
      #                          itemGroupName:    nil,
      #                          itemGroupRootId:  nil,
      #                          createdOn:        '2024-03-13T17:58:15.2338082Z',
      #                          modifiedOn:       '2024-03-13T17:58:15.3343468Z',
      #                          chargeable:       nil },
      #                        { id:               101909976,
      #                          sku:              { id:                       101352683,
      #                                              name:                     'Application Adjustment Deduct',
      #                                              displayName:              'Application Adjustment ',
      #                                              type:                     'Service',
      #                                              soldHours:                0.0,
      #                                              generalLedgerAccountId:   16401630,
      #                                              generalLedgerAccountName: 'Revenue-40000',
      #                                              modifiedOn:               '2024-03-04T17:19:20.2474978Z' },
      #                          skuAccount:       'Revenue-40000',
      #                          description:      'Deduction for every 1 foot less than 100',
      #                          membershipTypeId: nil,
      #                          qty:              60.0,
      #                          unitRate:         -100.0,
      #                          total:            -6000.0,
      #                          unitCost:         0.0,
      #                          totalCost:        0.0,
      #                          itemGroupName:    nil,
      #                          itemGroupRootId:  nil,
      #                          createdOn:        '2024-03-13T17:58:31.7810577Z',
      #                          modifiedOn:       '2024-03-13T17:58:31.8960636Z',
      #                          chargeable:       nil }],
      #     externalLinks:    [],
      #     subtotal:         8987.0,
      #     businessUnitId:   20080189,
      #     businessUnitName: 'Drains & Sewer Sales Residential - Harrisburg'
      #   },
      #   ...
      # ]
    end
  end
end
