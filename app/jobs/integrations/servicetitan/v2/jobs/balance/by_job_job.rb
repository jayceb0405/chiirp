# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/jobs/balance/by_job_job.rb
module Integrations
  module Servicetitan
    module V2
      module Jobs
        module Balance
          class ByJobJob < ApplicationJob
            # step # 3 (a Job)
            # update account balance for all ServiceTitan jobs within ClientApiIntegration.update_invoice_window_days range
            # Integrations::Servicetitan::V2::Jobs::Balance::ByJobJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Jobs::Balance::ByJobJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process          = (args.dig(:process).presence || 'servicetitan_update_job_balance_by_job').to_s
              @reschedule_secs  = 0
            end

            # perform the ActiveJob
            #   (req) client_id:         (Integer)
            #   (req) contact_job_id:    (Integer)
            #   (req) st_job_model:      (Hash)
            #   (req) st_customer_model: (Hash)
            def perform(**args)
              super

              return unless args.dig(:client_id).to_i.positive? && args.dig(:contact_job_id).to_i.positive? && args.dig(:st_job_model).is_a?(Hash) && args.dig(:st_customer_model).is_a?(Hash) &&
                            (contact_job = Contacts::Job.find_by(id: args[:contact_job_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              st_model.update_contact_from_job(st_job_model: args[:st_job_model], st_customer_model: args[:st_customer_model], ok_to_process_estimate_actions: false)

              return if (st_invoice_models = st_client.invoices(st_customer_id: args.dig(:st_customer_model, :id), st_job_id: args.dig(:st_job_model, :id))).blank?

              contact_job.update(outstanding_balance: st_invoice_models.sum { |im| im.dig(:balance).to_d }.to_d)
            end
            # example ServiceTitan Job Model
            # {
            #   id:                     123774744,
            #   jobNumber:              '123774744',
            #   projectId:              nil,
            #   customerId:             4024346,
            #   locationId:             5024346,
            #   jobStatus:              'Completed',
            #   completedOn:            '2024-03-21T18:41:34.535Z',
            #   businessUnitId:         16896583,
            #   jobTypeId:              48893461,
            #   priority:               'Urgent',
            #   campaignId:             11650351,
            #   summary:                '$79 DISPATCH FEE<br>COPPER PIPES IN BASEMENT ARE LEAKING<br>THUR 3/21',
            #   customFields:           [{ typeId: 22009859, name: 'Are you the homeowner?', value: 'Yes' }, { typeId: 22009604, name: 'Do you have a home warranty?', value: 'No' }],
            #   appointmentCount:       1,
            #   firstAppointmentId:     123774745,
            #   lastAppointmentId:      123774745,
            #   recallForId:            nil,
            #   warrantyId:             nil,
            #   jobGeneratedLeadSource: { jobId: nil, employeeId: nil },
            #   noCharge:               false,
            #   notificationsEnabled:   true,
            #   createdOn:              '2024-03-21T12:11:54.2435119Z',
            #   createdById:            55542156,
            #   modifiedOn:             '2024-03-21T18:41:36.2510065Z',
            #   tagTypeIds:             [134, 52955021],
            #   leadCallId:             123778060,
            #   bookingId:              nil,
            #   soldById:               nil,
            #   externalData:           nil,
            #   customerPo:             nil
            # }
            # example ServiceTitan Customer Model
            # {
            #   id:           4024346,
            #   active:       true,
            #   name:         'LEE SUSSMAN',
            #   type:         'Residential',
            #   address:      { street: '1551 Orchard Circle', unit: nil, city: 'Naperville', state: 'IL', zip: '60565', country: 'USA', latitude: 41.743072, longitude: -88.1226757 },
            #   customFields: [],
            #   balance:      0.0,
            #   tagTypeIds:   [19363252],
            #   doNotMail:    false,
            #   doNotService: false,
            #   createdOn:    '0001-01-01T00:00:00Z',
            #   createdById:  0,
            #   modifiedOn:   '2024-02-16T06:41:14.5711888Z',
            #   mergedToId:   nil,
            #   externalData: nil
            # }
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
    end
  end
end
