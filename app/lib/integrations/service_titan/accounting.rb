# frozen_string_literal: true

# app/lib/integrations/service_titan/accounting.rb
module Integrations
  module ServiceTitan
    module Accounting
      # call ServiceTitan API for an invoice
      # st_client.invoice
      #   (req) invoice_id: (Integer)
      def invoice(args = {})
        reset_attributes
        @result = {}

        if args.dig(:invoice_id).to_i.zero?
          @message = 'ServiceTitan Invoice ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Accounting.invoice',
          method:                'get',
          params:                { ids: args[:invoice_id].to_i },
          default_result:        {},
          url:                   "#{base_url}/#{api_method_accounting}/#{api_version}/tenant/#{self.tenant_id}/invoices"
        )

        if !@result.is_a?(Hash) || (response = @result&.dig(:data, 0) || {}).blank?
          response = {}
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result = response
      end

      # call ServiceTitan API for invoices on a customer/job
      # st_client.invoices
      #   (req) st_customer_id: (Integer)
      #   (req) st_job_id:      (Integer)
      #           ~ or ~
      #   (req) st_job_number   (Integer)
      def invoices(args = {})
        reset_attributes
        page     = 0
        @result  = []
        response = @result

        if args.dig(:st_customer_id).to_i.zero?
          @message = 'ServiceTitan Customer ID is required.'
          return @result
        elsif args.dig(:st_job_id).to_i.zero? && args.dig(:st_job_number).to_s.strip.empty?
          @message = 'ServiceTitan Job ID or Job Number is required.'
          return @result
        end

        params = {
          customerId: args[:st_customer_id].to_i,
          pageSize:   @page_size
        }
        params[:jobId]     = args[:st_job_id].to_i if args.dig(:st_job_id).to_i.positive?
        params[:jobNumber] = args[:st_job_number].to_s.strip if args.dig(:st_job_number).present?

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Accounting.invoices',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_accounting}/#{api_version}/tenant/#{self.tenant_id}/invoices"
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
      # example ServiceTitan invoice models
      # [
      #   {
      #     id:                        115492871,
      #     syncStatus:                'Exported',
      #     summary:                   "LANDLORD / TENANT 5/5/4/Y\n\nPerformed evaluation of a 15 year old system. I found safety, functionality, efficiency, indoor air quality, code violation, and property damage concerns. As soon as I opened the mechanical room door the smell of gas was present. I found a gas leak using an electronic combustion gas leak detector. The flexible gas line for the water heater should be hard piped. The 80% non condensing furnace has flue gas condensate leaking down the pipe which has compromised the internal galvanized coating and now the moisture is eating the steel. This moisture has leaked into and out of the primary collector fiberglass gasket and can eat a hole in the heat exchanger.  The circuit board is burnt on the rear and I found abnormal voltage at the R terminal which should only have 24 volts. This likely damaged the smart thermostat. The filter is plugged with debris. The air conditioner evaporator coil leaks condensation into the ductwork below and black mold was found. Black mold has the ability to travel through out the duct system and get into areas not easily reached such as in the walls. No homeowners policy covers mold damage without a mold Ryder. Took video and pictures of my findings. Confirmed with tenant on-site. Quoted options. \n\nTHE LANDLORD IS NOT ABLE TO BE GOTTEN AHOLD OF. NO PHONE NUMBER IS ON FILE FOR THE LANDLORD. WE CANT PERFORM WORK WITHOUT THE OWNER OF THE PROPERTIES APPROVAL. NO CREDIT CARD IS ON FILE SO NO WAY TO COLLECT FOR THE EVALUATION. ",
      #     referenceNumber:           '115492866',
      #     invoiceDate:               '2024-02-06T00:00:00Z',
      #     dueDate:                   '2024-02-06T00:00:00Z',
      #     subTotal:                  '79.00',
      #     salesTax:                  '0.00',
      #     salesTaxCode:              nil,
      #     total:                     '79.00',
      #     balance:                   '79.00',
      #     invoiceType:               nil,
      #     customer:                  { id: 115505689, name: 'REBECCA FORD ' },
      #     customerAddress:           { street: '2302 Wayland Lane', unit: nil, city: 'Naperville', state: 'IL', zip: '60565', country: 'USA' },
      #     location:                  { id: 115505692, name: 'REBECCA FORD ' },
      #     locationAddress:           { street: '2302 Wayland Lane', unit: nil, city: 'Naperville', state: 'IL', zip: '60565', country: 'USA' },
      #     businessUnit:              { id: 132, name: 'PF-HVAC: SVC' },
      #     termName:                  'Due Upon Receipt',
      #     createdBy:                 'Gabbysap',
      #     batch:                     { id: 115552943, number: '3581', name: 'service/plumbing' },
      #     depositedOn:               '2024-02-07T16:36:24.9268018Z',
      #     createdOn:                 '2024-02-06T18:16:40.7984656Z',
      #     modifiedOn:                '2024-02-07T16:37:45.4277412Z',
      #     adjustmentToId:            nil,
      #     job:                       { id: 115492866, number: '115492866', type: 'HVAC: Demand Service' },
      #     projectId:                 115512861,
      #     royalty:                   { status: 'Pending', date: nil, sentOn: nil, memo: nil },
      #     employeeInfo:              { id: 55542156, name: 'Gabbysap', modifiedOn: '2024-03-14T03:57:32.0699898Z' },
      #     commissionEligibilityDate: nil,
      #     sentStatus:                'NotSent',
      #     reviewStatus:              'NeedsReview',
      #     assignedTo:                nil,
      #     items:                     [{ id:                   115514766,
      #                                   description:          '<p>The dispatch fee covers:</p><ul><li>Technician travel time</li><li>Time to inspect the system to provide an estimate</li><li>Vehicle maintenance and fuel</li></ul>',
      #                                   quantity:             '1.0000000000000000000',
      #                                   cost:                 '0.0000000000',
      #                                   totalCost:            '0.00',
      #                                   inventoryLocation:    nil,
      #                                   price:                '79.00',
      #                                   type:                 'Service',
      #                                   skuName:              'DIAG1',
      #                                   skuId:                10016994,
      #                                   total:                '79.00',
      #                                   inventory:            false,
      #                                   taxable:              false,
      #                                   generalLedgerAccount: { id: 82130700, name: '41000-Sales:Res. HVAC Service', number: '77', type: 'Income', detailType: 'Income' },
      #                                   costOfSaleAccount:    nil,
      #                                   assetAccount:         nil,
      #                                   membershipTypeId:     0,
      #                                   itemGroup:            nil,
      #                                   displayName:          'Dispatch Fee',
      #                                   soldHours:            0.19,
      #                                   modifiedOn:           '2024-02-06T20:49:23.8337178Z',
      #                                   serviceDate:          '2024-02-06T00:00:00Z',
      #                                   order:                1,
      #                                   businessUnit:         { id: 132, name: 'PF-HVAC: SVC' } }],
      #     customFields:              nil
      #   },
      #   ...
      # ]
    end
  end
end
