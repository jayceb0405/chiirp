# frozen_string_literal: true

# app/lib/integrations/service_titan/reports.rb
module Integrations
  module ServiceTitan
    module Reports
      # call ServiceTitan API for a list of Report Categories
      # st_client.report_categories()
      #   (opt) include_total: (Boolean / default: true)
      def report_categories(args = {})
        reset_attributes
        @result  = []
        page     = 0
        response = @result

        params = { pageSize: @max_page_size }
        params[:includeTotal] = args.dig(:include_total).nil? ? true : args[:include_total].to_bool

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Reports.report_categories',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_reporting}/#{api_version}/tenant/#{self.tenant_id}/report-categories"
          )

          if @result.is_a?(Hash)
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
      # example @result
      # [
      #   {:id=>"marketing", :name=>"Marketing"},
      #   {:id=>"operations", :name=>"Operations"},
      #   {:id=>"accounting", :name=>"Accounting"},
      #   {:id=>"technician", :name=>"Technician"},
      #   ...
      # ]

      # call ServiceTitan API for a dynamic data set
      # st_client.report_dynamic_data_set()
      #   (req) dynamic_set_id: (Integer)
      def report_dynamic_data_set(dynamic_set_id)
        reset_attributes
        @result = []

        if dynamic_set_id.to_s.empty?
          @message = 'ServiceTitan Dynamic Data Set id is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Reports.report_dynamic_data_set',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_reporting}/#{api_version}/tenant/#{self.tenant_id}/dynamic-value-sets/#{dynamic_set_id}?pageSize=#{@page_size}"
        )

        if @result.is_a?(Hash)
          @result = @result.dig(:data) || []
        else
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end
      # example ServiceTitan Dynamic Data Set Faraday Result (invoice statuses)
      # {
      #   status: 200,
      #   body:   {
      #     fields:     [
      #       { name: 'Value', label: 'Value' },
      #       { name: 'Name', label: 'Name' }
      #     ],
      #     page:       1,
      #     pageSize:   500,
      #     hasMore:    false,
      #     totalCount: nil,
      #     data:       [
      #       [0, 'Pending'], [1, 'Posted'], [2, 'Exported']
      #     ]
      #   }
      # }
      # example ServiceTitan Dynamic Data Set Faraday Result (membership statuses)
      # {
      #   status: 200,
      #   body:   {
      #     fields:     [
      #       { name: 'Value', label: 'Value' },
      #       { name: 'Name', label: 'Name' }
      #     ],
      #     page:       1,
      #     pageSize:   500,
      #     hasMore:    false,
      #     totalCount: nil,
      #     data:       [
      #       [0, 'Active'],
      #       [1, 'Suspended'],
      #       [2, 'Expired'],
      #       [3, 'Canceled'],
      #       [4, 'Deleted']
      #     ]
      #   }
      # }

      # call ServiceTitan API for info on a specific Report
      # st_client.report()
      #   (req) category_id:  (String)
      #   (req) report_id: (Integer)
      def report(args = {})
        reset_attributes
        @result = {}

        if args.dig(:category_id).to_s.empty?
          @message = 'ServiceTitan Category is required.'
          return @result
        elsif args.dig(:report_id).to_i.zero?
          @message = 'ServiceTitan Report ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Reports.report',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_reporting}/#{api_version}/tenant/#{self.tenant_id}/report-category/#{args[:category_id]}/reports/#{args[:report_id].to_i}"
        )

        unless @result.is_a?(Hash)
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end
      # example @result
      # {
      #   :id=>65746009,
      #   :name=>"Active Memberships",
      #   :description=>"Upgraded version of the legacy Active Member Report. Use this report to audit your customers' memberships. This report includes information about the membership status, duration, billing cadence, the sold by technician, and customer contact information. ",
      #   :modifiedOn=>"2023-05-16T11:38:25.9746593-04:00",
      #   :parameters=>[
      #     {:name=>"From", :label=>"Sold On From", :dataType=>"Date", :isArray=>false, :isRequired=>false, :acceptValues=>nil},
      #     {:name=>"To", :label=>"Sold On To", :dataType=>"Date", :isArray=>false, :isRequired=>false, :acceptValues=>nil},
      #     {:name=>"MemberFrom", :label=>"Membership From", :dataType=>"Date", :isArray=>false, :isRequired=>false, :acceptValues=>nil},
      #     {:name=>"MemberTo", :label=>"Membership To", :dataType=>"Date", :isArray=>false, :isRequired=>false, :acceptValues=>nil},
      #     {:name=>"BusinessUnitIds", :label=>"Membership Business Unit", :dataType=>"Number", :isArray=>true, :isRequired=>false, :acceptValues=>{:fields=>[{:name=>"Value", :label=>"Value"}, {:name=>"Name", :label=>"Name"}], :dynamicSetId=>"business-units", :values=>nil}},
      #     {:name=>"MembershipTypeIds", :label=>"Membership Type", :dataType=>"Number", :isArray=>true, :isRequired=>false, :acceptValues=>{:fields=>[{:name=>"Value", :label=>"Value"}, {:name=>"Name", :label=>"Name"}], :dynamicSetId=>"membership-types", :values=>nil}},
      #     {:name=>"Statuses", :label=>"Membership Status", :dataType=>"Number", :isArray=>true, :isRequired=>false, :acceptValues=>{:fields=>[{:name=>"Value", :label=>"Value"}, {:name=>"Name", :label=>"Name"}], :dynamicSetId=>"membership-statuses", :values=>nil}},
      #     {:name=>"StatusAsOfDate", :label=>"Status As Of Date", :dataType=>"Date", :isArray=>false, :isRequired=>false, :acceptValues=>nil},
      #     {:name=>"DeferredRevenueAsOf", :label=>"Deferred Revenue As of Date", :dataType=>"Date", :isArray=>false, :isRequired=>false, :acceptValues=>nil},
      #     {:name=>"InvoiceStatuses", :label=>"Deferred Revenue Invoice Status", :dataType=>"Number", :isArray=>true, :isRequired=>false, :acceptValues=>{:fields=>[{:name=>"Value", :label=>"Value"}, {:name=>"Name", :label=>"Name"}], :dynamicSetId=>"invoice-statuses", :values=>nil}}],
      #     {:name=>"RecurringServiceTypes", :label=>"Recurring Service Type", :isArray=>true, :dataType=>"Number", :isRequired=>false, :acceptValues=>{:fields=>[{:name=>"Value", :label=>"Value"}, {:name=>"Name", :label=>"Name"}], :values=>[[61136806, "Fall Maintenance (Fixed/1 Year)"], [49445598, "Fall Maintenance (Ongoing)"], [61160099, "Spring Maintenance (Fixed/1 Year)"], [16406735, "Spring Maintenance (Ongoing)"]], :dynamicSetId=>null}},
      #   :fields=>[
      #     {:name=>"CustomerType", :label=>"Customer Type", :dataType=>"String"},
      #     {:name=>"CustomerName", :label=>"Customer Name", :dataType=>"String"},
      #     {:name=>"CustomerAddress", :label=>"Customer Address", :dataType=>"String"},
      #     {:name=>"LocationAddress", :label=>"Location Address", :dataType=>"String"},
      #     {:name=>"CustomerEmail", :label=>"Customer Email", :dataType=>"String"},
      #     {:name=>"CustomerPhone", :label=>"Customer Phone", :dataType=>"String"},
      #     {:name=>"MembershipType", :label=>"Membership Type", :dataType=>"String"},
      #     {:name=>"MembershipStatus", :label=>"Membership Status", :dataType=>"String"},
      #     {:name=>"MembershipDuration", :label=>"Membership Duration", :dataType=>"Number"},
      #     {:name=>"BillingCadence", :label=>"Billing Cadence", :dataType=>"String"},
      #     {:name=>"From", :label=>"From", :dataType=>"Date"},
      #     {:name=>"To", :label=>"To", :dataType=>"Date"},
      #     {:name=>"SoldBy", :label=>"Sold By", :dataType=>"String"},
      #     {:name=>"StatusAsOf", :label=>"Status As Of", :dataType=>"String"}
      #   ]
      # }

      # call ServiceTitan API for Report results
      # st_client.report_results()
      #   (req) category:      (String)
      #   (opt) include_total: (Boolean)
      #   (opt) page:          (Integer)
      #   (opt) page_size:     (Integer)
      #   (opt) parameters:    (Array) ie: [{ name: String, value: String }]
      #   (req) report_id:     (Integer)
      def report_results(args = {})
        reset_attributes
        @result = { fields: [], data: [] }

        if args.dig(:category).blank?
          @message = 'ServiceTitan Category is required.'
          return @result
        elsif args.dig(:report_id).to_i.zero?
          @message = 'ServiceTitan Report ID is required.'
          return @result
        end

        # page     = (args.dig(:page) || 1).to_i - 1
        page     = 0
        response = @result
        # params   = { pageSize: (args.dig(:page_size) || @page_size).to_i }
        params   = { pageSize: 25_000 }
        params[:includeTotal] = args[:include_total].to_bool if args.include?(:include_total)
        body = { parameters: args.dig(:parameters) || [] }

        # loop do
        page += 1
        params[:page] = page

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::Reports.report_results',
          method:                'post',
          params:,
          default_result:        [],
          url:                   "#{base_url}/#{api_method_reporting}/#{api_version}/tenant/#{self.tenant_id}/report-category/#{args[:category]}/reports/#{args[:report_id]}/data"
        )

        if @result.is_a?(Hash)
          response[:data] += @result.dig(:data) || []
          response[:fields] += @result.dig(:fields) || []
          @message = 'More than 25,000 results were found. Only the first 25,000 may be displayed.' if @result.dig(:hasMore).to_bool
          # break if args.dig(:page).to_i.positive?
          # break unless @result.dig(:hasMore).to_bool
        else
          response = { fields: [], data: [] }
          @success = false
          @message = @error.to_i == 429 ? @message : "Unexpected response: #{@result.inspect}"
          # break
        end
        # end

        @result = response
      end
      # example @faraday_result
      # {
      #   status: 200,
      #   body: {
      #     fields: [
      #       { name: "CustomerName", label: "Customer Name" },
      #       { name: "CustomerType", label: "Customer Type" },
      #       { name: "MembershipType", label: "Membership Type" },
      #       { name: "MembershipStatus", label: "Membership Status" },
      #       { name: "CustomerPhone", label: "Customer Phone" },
      #       { name: "LocationPhone", label: "Location Phone" },
      #       { name: "CustomerEmail", label: "Customer Email" },
      #       { name: "CustomerStreet", label: "Customer Street" },
      #       { name: "CustomerCity", label: "Customer City" },
      #       { name: "CustomerState", label: "Customer State" },
      #       { name: "CustomerZip", label: "Customer Zip" },
      #       { name: "LocationStreet", label: "Location Street" },
      #       { name: "LocationCity", label: "Location City" },
      #       { name: "LocationState", label: "Location State" },
      #       { name: "LocationZip", label: "Location Zip" },
      #       { name: "From", label: "From" },
      #       { name: "To", label: "To" },
      #       { name: "RenewedInto", label: "Renewed Into"},
      #       { name: "MembershipPrice", label: "Membership Sale/Renewal Price" }
      #     ],
      #     page: 1,
      #     pageSize: 25000,
      #     hasMore: false,
      #     totalCount: nil,
      #     data: [
      #       [" Estancia Day Spa & Salon", "Commercial", "COMM-M12 (Deactivate)", "Canceled", "(559) 908-5694", "(559) 908-5694", "erinsalisch@comcast.net", "2950 East Nees Avenue", "Fresno", "CA", "93720", "2950 East Nees Avenue", "Fresno", "CA", "93720", "2021-07-15T00:00:00-07:00",nil,"",980.44],
      #       [" Hossein Gabatabai", "Commercial", "COMM-M20 (Deactivate)", "Active", "(925) 580-1340, (559) 593-0392", "(925) 580-1340, (559) 977-8908", "hossein@transbayfire.com", "6245 North Knoll Avenue", "Fresno", "CA", "93711", "4672 West Jennifer Avenue", "Fresno", "CA", "93722", "2023-03-20T00:00:00-07:00",nil,"",0.00],
      #       [" In Shape Health Club", "Commercial", "COMM-M20 (Deactivate)", "Suspended", "(201) 344-9216, (808) 284-2267", "", "ap@inshape.com", "6 S. E. Dorado St. Ste 700", "Stockton", "CA", "95202",nil,nil,nil,nil,"2019-02-25T00:00:00-08:00",nil,"",0.0],
      #       [" K4 Management", "Commercial", "COMM-M12 (Deactivate)", "Canceled", "(559) 284-8926, (559) 307-7966, (559) 320-0288 x105",nil,"dpalmer@k4management.com, jschuh@k4management.com, pharvey@k4management.com", "265 East River Park Circle", "Fresno", "CA", "93720", "4416 West Shaw Avenue", "Fresno", "CA", "93722", "2015-01-01T00:00:00-08:00",nil,"",0.0],
      #       [" K4 Management", "Commercial", "COMM-M12 (Deactivate)", "Canceled", "(559) 284-8926, (559) 307-7966, (559) 320-0288 x105",nil,"dpalmer@k4management.com, jschuh@k4management.com, pharvey@k4management.com", "265 East River Park Circle", "Fresno", "CA", "93720", "7543 North Ingram Avenue", "Fresno", "CA", "93711", "2015-01-01T00:00:00-08:00",nil,"",0.0],
      #       [" K4 Management", "Commercial", "COMM-M12 (Deactivate)", "Canceled", "(559)284-8926, (559) 307-7966, (559) 320-0288 x105", "(559) 307-7966", "dpalmer@k4management.com, jschuh@k4management.com, pharvey@k4management.com", "265 East River Park Circle", "Fresno", "CA", "93720", "780-786 W. Palmdon", "Fresno", "CA", "93720", "2015-01-01T00:00:00-08:00",nil,"",0.0],
      #       [" Massage Envy Spa (1170 E. Champlain Dr)", "Commercial", "COMM-M12 (Deactivate)", "Canceled", "(775) 850-5823", "(559) 434-0900, (559) 900-2080", "mgr1168@massageenvy.com", "59 Damonte Ranch", "Reno", "NV", "89521", "1170 E. Champlain Drive", "Fresno", "CA", "93720", "2017-07-20T00:00:00-07:00",nil,"",0.0],
      #       [" Postal Annex # 2010", "Commercial", "COMMERCIAL-M", "Canceled", "(559) 217-0380", "", "verrastrojohn@aol.com", "c/o John Verrastro", "Clovis", "CA", "93611",nil,nil,nil,nil,"2017-04-11T00:00:00-07:00", "2116-04-11T00:00:00-07:00", "",0.0],
      #       [" Trinity Warranty Solutions", "Commercial", "COMM-M12 (Deactivate)", "Active", "(877) 302-5072, (630) 621-8197, (630) 310-9933, (312) 445-8726, (630) 601-9558",nil,"johnsona@trinitywarranty.com, tnadocs@trinitywarranty.com, tnaservicecall@trinitywarranty.com, getkina@trinitywarranty.com, lhotkab@trinitywarranty.com, ZielinM@trinitywarranty.com, wellerk@trinitywarranty.com, scibisi@trinitywarranty.com", "1919 South Highland Avenue", "Lombard", "IL", "60148", "3140 West Shaw Avenue", "Fresno", "CA", "93711", "2020-09-01T00:00:00-07:00",nil,"",0.00],
      #       [" Trinity Warranty Solutions", "Commercial", "COMM-M12 (Deactivate)", "Active", "(877) 302-5072, (630) 621-8197, (630) 310-9933, (312) 445-8726, (630) 601-9558",nil,"johnsona@trinitywarranty.com, tnadocs@trinitywarranty.com, tnaservicecall@trinitywarranty.com, getkina@trinitywarranty.com, lhotkab@trinitywarranty.com, ZielinM@trinitywarranty.com, wellerk@trinitywarranty.com, scibisi@trinitywarranty.com", "1919 South Highland Avenue", "Lombard", "IL", "60148", "7675 North Blackstone Avenue", "Fresno", "CA", "93711", "2020-09-01T00:00:00-07:00",nil,"",0.00],
      #       ...
      #     ]
      #   },
      # }

      # call ServiceTitan API for a list of Reports
      # st_client.reports()
      #   (req) st_report_category_id: (String)
      #   (opt) include_total:         (Boolean / default: nil)
      #   (opt) page:                  (Integer / default: 0)
      #   (opt) page_size:             (Integer / default: @max_page_size)
      def reports(args = {})
        reset_attributes
        @result  = []
        page     = (args.dig(:page) || 1).to_i - 1
        response = @result

        if args.dig(:st_report_category_id).blank?
          @message = 'ServiceTitan Category is required.'
          return @result
        end

        params = { pageSize: (args.dig(:page_size) || @max_page_size).to_i }
        params[:includeTotal] = args[:include_total].to_bool if args.include?(:include_total)

        loop do
          page += 1

          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Reports.reports',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_reporting}/#{api_version}/tenant/#{self.tenant_id}/report-category/#{args[:st_report_category_id]}/reports"
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
      # example @result
      # [
      #   {
      #     :id=>65746009,
      #     :name=>"Active Memberships",
      #     :description=>
      #      "Upgraded version of the legacy Active Member Report. Use this report to audit your customers' memberships. This report includes information about the membership status, duration, billing cadence, the sold by technician, and customer contact information. "
      #   },
      #   {
      #     :id=>104626612,
      #     :name=>"Aging Equipment Custom Report",
      #     :description=>"Aging equipment by customer record, 10 years or older"
      #   },
      #   {
      #     :id=>76979251,
      #     :name=>"BU Performancce",
      #     :description=>nil
      #   },
      #   {
      #     :id=>109337585,
      #     :name=>"Campaign Summary",
      #     :description=>nil
      #   },
      #   ...
      # ]
    end
  end
end
