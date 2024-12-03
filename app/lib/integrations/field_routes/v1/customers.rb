# frozen_string_literal: true

# app/lib/integrations/field_routes/v1/customers.rb
module Integrations
  module FieldRoutes
    module V1
      module Customers
        def customer_ids(filter = {})
          reset_attributes
          @result = {}

          params = {}
          params[:active]           = filter[:active_only].to_bool ? 1 : 0 unless filter.dig(:active_only).nil?
          # params[:officeIDs]        = { operator: 'CONTAINS', value: filter[:office_ids] } if filter.dig(:office_ids).is_a?(Array)
          params[:dateAddedStart]   = { operator: '>', value: filter[:created_at][:after].iso8601 } if filter.dig(:created_at, :after).respond_to?(:iso8601)
          params[:dateAddedEnd]     = { operator: '<', value: filter[:created_at][:before].iso8601 } if filter.dig(:created_at, :before).respond_to?(:iso8601)
          params[:dateUpdatedStart] = { operator: '>', value: filter[:updated_at][:after].iso8601 } if filter.dig(:updated_at, :after).respond_to?(:iso8601)
          params[:dateUpdatedEnd]   = { operator: '<', value: filter[:updated_at][:before].iso8601 } if filter.dig(:updated_at, :before).respond_to?(:iso8601)

          fieldroutes_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldRoutes::V1::Customers.customer_ids',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   "#{api_url}/customer/search"
          )

          @result
        end
        # example response
        # {
        #   params:         {
        #     endpoint:            'customer',
        #     action:              'search',
        #     active:              '1',
        #     authenticationKey:   '8hg79rnoe1v68b82ueis26ocdh6vm3h07kojbjjtvchrsnndvjom09nisdgppgnj',
        #     authenticationToken: 'mr609s332q4g6bosi6jrci1bbohbehrjumla563e57cc55gje3eklgm3v0l1vlo4',
        #     dateAddedEnd:        { operator: '<', value: '2024-07-21T18:07:12Z' },
        #     officeIDs:           { operator: 'CONTAINS', value: ['1'] }
        #   },
        #   tokenUsage:     { requestsReadToday: 326, requestsWriteToday: 8, requestsReadInLastMinute: 2, requestsWriteInLastMinute: 0 },
        #   tokenLimits:    { limitReadRequestsPerMinute: 60, limitReadRequestsPerDay: 3000, limitWriteRequestsPerMinute: 60, limitWriteRequestsPerDay: 3000 },
        #   requestAction:  'search',
        #   endpoint:       'customer',
        #   success:        true,
        #   idName:         'customerIDs',
        #   processingTime: '48 milliseconds',
        #   count:          2409,
        #   customerIDs:    [1, 2, 3, 4, 5, 14, 19, 21, 28, 29, 30, 52, 53, 64, 66, 115, 122, 156, 177, 181, 182, 194, 198, 209, 219, 231, 490, 594, 635, 1053, 1368, 1422, 1423, 1492, 1622, 1902, 2084, 2288, 2291, 2613, 2754, 2904, 2951, 3007, 3677, 3716, 4576, 4775, 4910, 4923, 4930, 4931, 4947],
        #   propertyName:   'customerIDs'
        # }

        def customers(customer_ids)
          reset_attributes
          @result = {}

          if customer_ids.blank? || !customer_ids.is_a?(Array)
            @message = 'FieldRoutes customer_ids must be an array of strings'
            return @result
          end

          params = { customerIDs: customer_ids }

          fieldroutes_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldRoutes::V1::Customers.customers',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   "#{api_url}/customer/get"
          )

          @result
        end
        # example response
        # {
        #   params:         {
        #     endpoint:            'customer',
        #     action:              'get',
        #     authenticationKey:   '8hg79rnoe1v68b82ueis26ocdh6vm3h07kojbjjtvchrsnndvjom09nisdgppgnj',
        #     authenticationToken: 'mr609s332q4g6bosi6jrci1bbohbehrjumla563e57cc55gje3eklgm3v0l1vlo4',
        #     customerIDs:         %w[1 2 3 4 5 14 19 21 28 29 30 52 53 64 66 115 122 156 177 181 182 194 198 209 219 231 490 594 635 1053 1368 1422 1423 1492 1622 1902 2084 2288 2291 2613 2754 2904 2951 3007 3677 3716 4576 4775 4910 4923]
        #   },
        #   tokenUsage:     { requestsReadToday: 229, requestsWriteToday: 6, requestsReadInLastMinute: 2, requestsWriteInLastMinute: 0 },
        #   tokenLimits:    { limitReadRequestsPerMinute: 60, limitReadRequestsPerDay: 3000, limitWriteRequestsPerMinute: 60, limitWriteRequestsPerDay: 3000 },
        #   requestAction:  'get',
        #   endpoint:       'customer',
        #   success:        true,
        #   processingTime: '321 milliseconds',
        #   count:          50,
        #   customers:      [
        #     {
        #       customerID:                         '1',
        #       billToAccountID:                    '1',
        #       officeID:                           '-1',
        #       fname:                              'John',
        #       lname:                              'Doe',
        #       companyName:                        '',
        #       spouse:                             nil,
        #       commercialAccount:                  '0',
        #       status:                             '1',
        #       statusText:                         'Active',
        #       email:                              'j.summerhays@choosepestcity.com',
        #       phone1:                             '',
        #       ext1:                               '',
        #       phone2:                             '',
        #       ext2:                               '',
        #       address:                            '7750 John Q Hammons',
        #       city:                               'Frisco',
        #       state:                              'TX',
        #       zip:                                '75034',
        #       billingCompanyName:                 '',
        #       billingFName:                       'John',
        #       billingLName:                       'Doe',
        #       billingCountryID:                   'US',
        #       billingAddress:                     '7750 John Q Hammons',
        #       billingCity:                        'dallas',
        #       billingState:                       'TX',
        #       billingZip:                         '75034',
        #       billingPhone:                       '',
        #       billingEmail:                       'j.summerhays@choosepestcity.com',
        #       lat:                                '33.099316',
        #       lng:                                '-96.817650',
        #       squareFeet:                         '0',
        #       addedByID:                          '1',
        #       dateAdded:                          '2017-03-22 09:42:39',
        #       dateCancelled:                      '0000-00-00 00:00:00',
        #       dateUpdated:                        '2017-03-31 09:50:41',
        #       sourceID:                           '0',
        #       source:                             nil,
        #       aPay:                               'No',
        #       preferredTechID:                    '0',
        #       paidInFull:                         '0',
        #       subscriptionIDs:                    '1',
        #       balance:                            '0.00',
        #       balanceAge:                         '0',
        #       responsibleBalance:                 '0.00',
        #       responsibleBalanceAge:              '0',
        #       customerLink:                       '1',
        #       masterAccount:                      '0',
        #       preferredBillingDate:               '0',
        #       paymentHoldDate:                    nil,
        #       mostRecentCreditCardLastFour:       nil,
        #       mostRecentCreditCardExpirationDate: nil,
        #       regionID:                           '0',
        #       mapCode:                            '',
        #       mapPage:                            '',
        #       specialScheduling:                  '',
        #       taxRate:                            '0.000000',
        #       stateTax:                           '0.000000',
        #       cityTax:                            '0.000000',
        #       countyTax:                          '0.000000',
        #       districtTax:                        '0.000000',
        #       districtTax1:                       '0.000000',
        #       districtTax2:                       '0.000000',
        #       districtTax3:                       '0.000000',
        #       districtTax4:                       '0.000000',
        #       districtTax5:                       '0.000000',
        #       customTax:                          '0.000000',
        #       zipTaxID:                           '466225',
        #       smsReminders:                       '1',
        #       phoneReminders:                     '1',
        #       emailReminders:                     '1',
        #       customerSource:                     nil,
        #       customerSourceID:                   '0',
        #       maxMonthlyCharge:                   '0.00',
        #       county:                             'Denton',
        #       useStructures:                      '0',
        #       isMultiUnit:                        '0',
        #       autoPayPaymentProfileID:            nil,
        #       divisionID:                         '-1',
        #       subPropertyTypeID:                  '0',
        #       agingDate:                          '2017-04-06',
        #       responsibleAgingDate:               '2017-04-06',
        #       salesmanAPay:                       '0',
        #       purpleDragon:                       '0',
        #       termiteMonitoring:                  '0',
        #       pendingCancel:                      '0',
        #       appointmentIDs:                     '1,2',
        #       ticketIDs:                          nil,
        #       paymentIDs:                         nil,
        #       unitIDs:                            []
        #     },...
        #   ]
        # }
      end
    end
  end
end
