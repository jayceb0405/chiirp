# frozen_string_literal: true

# app/controllers/integrations/servicetitan/webhook_samples_controller.rb
# rubocop:disable all
module Integrations
  module Servicetitan
    class WebhookSamplesController < Servicetitan::IntegrationsController
      def callcompleted_webhook_params
        {
          eventId: "string",
          webhookId: 0,
          __eventInfo: {
            eventId: "string",
            webhookId: 0
          },
          __tenantInfo: {
            name: "string",
            id: 0
          },
          id: 0,
          receivedOn: "2022-06-08T14:58:33.473Z",
          duration: "string",
          from: "string",
          to: "string",
          direction: "Inbound",
          callType: "Abandoned",
          reason: {
            id: 0,
            name: "string",
            lead: true,
            active: true
          },
          recordingUrl: "string",
          voiceMailUrl: "string",
          createdBy: {
            id: 0,
            name: "string"
          },
          customer: {
            id: 0,
            active: true,
            name: "string",
            email: "string",
            balance: 0,
            doNotMail: true,
            address: {
              street: "string",
              unit: "string",
              country: "string",
              city: "string",
              state: "string",
              zip: "string",
              streetAddress: "string",
              latitude: 0,
              longitude: 0
            },
            importId: "string",
            doNotService: true,
            type: "Residential",
            contacts: [
              {
                active: true,
                modifiedOn: "2022-06-08T14:58:33.473Z",
                id: 0,
                type: "string",
                value: "string",
                memo: "string"
              }
            ],
            mergedToId: 0,
            modifiedOn: "2022-06-08T14:58:33.473Z",
            memberships: [
              {
                id: 0,
                active: true,
                type: {
                  id: 0,
                  active: true,
                  name: "string"
                },
                status: "string",
                from: "2022-06-08T14:58:33.473Z",
                to: "2022-06-08T14:58:33.473Z",
                locationId: 0
              }
            ],
            hasActiveMembership: true,
            customFields: [
              {
                typeId: 0,
                name: "string",
                value: "string"
              }
            ],
            createdOn: "2022-06-08T14:58:33.473Z",
            createdBy: 0,
            phoneSettings: [
              {
                phoneNumber: "string",
                doNotText: true
              }
            ]
          },
          campaign: {
            category: {
              id: 0,
              name: "string",
              active: true
            },
            id: 0,
            name: "string",
            modifiedOn: "2022-06-08T14:58:33.473Z",
            active: true
          },
          modifiedOn: "2022-06-08T14:58:33.473Z",
          agent: {
            externalId: 0,
            id: 0,
            name: "string"
          }
        }
      end

      # example ServiceTitan customer_memberships
      [
        {
          :id=>21062330,
          :createdOn=>"2018-09-24T21:46:31.376687Z",
          :createdById=>2305,
          :modifiedOn=>"2022-06-28T10:31:26.6221904Z",
          :followUpOn=>"0001-01-01T00:00:00Z",
          :cancellationDate=>nil,
          :from=>"2018-09-10T00:00:00Z",
          :nextScheduledBillDate=>nil,
          :to=>"2019-09-10T00:00:00Z",
          :billingFrequency=>"OneTime",
          :renewalBillingFrequency=>nil,
          :status=>"Expired",
          :followUpStatus=>"NotAttempted",
          :active=>true,
          :initialDeferredRevenue=>0.0,
          :duration=>12,
          :renewalDuration=>nil,
          :businessUnitId=>272,
          :customerId=>10002084,
          :membershipTypeId=>13953,
          :activatedById=>2305,
          :activatedFromId=>nil,
          :billingTemplateId=>nil,
          :cancellationBalanceInvoiceId=>nil,
          :cancellationInvoiceId=>nil,
          :followUpCustomStatusId=>nil,
          :locationId=>10002086,
          :paymentMethodId=>nil,
          :paymentTypeId=>nil,
          :recurringLocationId=>10002086,
          :renewalMembershipTaskId=>nil,
          :renewedById=>nil,
          :soldById=>nil,
          :customerPo=>nil,
          :importId=>nil,
          :memo=>"Complimentary Furnace and AC tune up"
        }
      ]

      # example ServiceTitan jobcomplete webhook params
      def jobcomplete_webhook_params
        {
          id: 51340759,
          end: "2023-02-11T19:00:00",
          tags: [
            {
              id: 51340769,
              name: "Flexible 1-3 days ",
              ownerId: 51340759
            },
            {
              id: 51340770,
              name: "P-3",
              ownerId: 51340759
            }
          ],
          type: {
            id: 35453397,
            name: "Furnace Heating Problem >5",
            modifiedOn: "2022-10-06T12:35:12.2607317"
          },
          start: "2023-02-11T17:00:00",
          action: "endpoint",
          active: true,
          status: "Completed",
          booking: nil,
          eventId: "2023-02-11T18:51:13.8312133Z",
          history: [
            {
              id: 51340772,
              date: "2023-02-11T16:20:24.6252105",
              start: "2023-02-11T17:00:00",
              employee: {
                id: 44743648,
                name: "Jade Price ",
                role: "CSR",
                type: "Employee",
                email: "tripleservicecsr@gmail.com",
                active: true,
                loginName: "Jade11",
                modifiedOn: "2023-02-03T21:38:33.357153",
                phoneNumber: "8156159233108",
                businessUnitId: nil
              },
              eventType: "Job Booked",
              usedSchedulingTool: 0
            }
          ],
          invoice: {
            id: 51340762,
            tax: 0.0,
            items: [
              {
                id: 51339247,
                qty: 1.0,
                sku: {
                  id: 9287509,
                  name: "Safety Concern",
                  type: "Service",
                  soldHours: 0.0,
                  modifiedOn: "2021-12-30T19:23:30.2498505",
                  displayName: "Safety Concern",
                  generalLedgerAccountId: 8994734,
                  generalLedgerAccountName: "Sales"
                },
                order: 2,
                total: 0.0,
                active: true,
                unitRate: 0.0,
                invoiceId: 51340762,
                salesType: 0,
                totalCost: 0.0,
                modifiedOn: "2023-02-11T18:43:37.2311585",
                description: "Safety Concern",
                membershipTypeId: nil
              },
              {
                id: 51344360,
                qty: 1.0,
                sku: {
                  id: 20949461,
                  name: "112drainminor",
                  type: "Service",
                  soldHours: 0.25,
                  modifiedOn: "2023-01-21T09:26:28.2009492",
                  displayName: "MInor Adjustment, Cleaning or Repair",
                  generalLedgerAccountId: 8994734,
                  generalLedgerAccountName: "Sales"
                },
                order: 1,
                total: 73.0,
                active: true,
                unitRate: 73.0,
                invoiceId: 51340762,
                salesType: 0,
                totalCost: 0.0,
                modifiedOn: "2023-02-11T18:43:26.9287163",
                description: "Minor adjustment, cleaning or repair. This task required no parts",
                membershipTypeId: nil
              }
            ],
            jobId: 51340759,
            total: 73.0,
            active: true,
            number: "51340759",
            status: {
              name: "Pending",
              value: 0,
              depositedOn: nil
            },
            balance: 0.0,
            batchId: 0,
            summary: "I arrived at the home. The furnace was off. I made my way to the furnace and took the doors off then I went upstairs to the thermostat and turned the heat on. Customer says they heard a loud scratching noise like metal on metal. I did notice when I went back down to the furnace that the inducer motor it’s louder than it should be. I checked the amp draw on the inducer but the numbers were right about where they needed to be. I waited for the blower fan to kick in to see if that’s where the noise was coming from. I could not hear any scratching noises coming from the fan. I took the filter out and put it back in and there was still no noise. After the furnace would run for a couple of minutes the inducer motor starts to get louder and the amp draw drops about 50%. \n\nThe inducer motor is a concern, and I did priced out a new one for the customer. They do want Andy to come out for a free estimate this Monday before bandaid repair is done.",
            payments: [
              {
                id: 51338739,
                memo: "",
                type: {
                  id: 63,
                  name: "Check",
                  modifiedOn: "2021-10-29T18:33:00.2704312"
                },
                active: true,
                amount: 73.0,
                paidOn: "2023-02-11T00:00:00",
                batchId: 0,
                batchName: nil,
                invoiceId: 51340762,
                modifiedOn: "2023-02-11T18:44:16.0784194",
                batchNumber: 0,
                totalAmount: 222.0,
                transaction: nil,
                paymentSplitId: 51338740,
                settlementDate: nil,
                settlementStatus: nil
              }
            ],
            subtotal: 73.0,
            batchName: nil,
            jobNumber: "51340759",
            customerId: 3182411,
            invoicedOn: "2023-02-11T00:00:00",
            modifiedOn: "2023-02-11T18:51:13.0239971",
            batchNumber: 0,
            royaltyDate: nil,
            royaltyMemo: nil,
            businessUnit: {
              id: 1795,
              name: "HVAC - Service",
              email: "service@tripleserviceinc.com",
              active: true,
              tenant: {
                id: 737513509,
                name: "tripleserviceinc",
                modifiedOn: "2023-01-18T06:41:02.0638366",
                conceptCode: "NotSet"
              },
              address: {
                zip: "61342",
                city: "Mendota",
                unit: nil,
                state: "Illinois",
                street: "801 Monroe St",
                country: "United States"
              },
              currency: "USD",
              modifiedOn: "2022-10-06T12:36:44.7969959",
              conceptCode: "NotSet",
              phoneNumber: "(815) 539-3828",
              officialName: "Triple Service, Inc.",
              invoiceHeader: "Triple Service Inc\n801 Monroe St\nMendota, IL\n61342",
              defaultTaxRate: 0.0,
              invoiceMessage: "Thank you for your business!",
              quickbooksClass: nil,
              authorizationParagraph: "I, the undersigned, am the owner or authorized representative of the premises at the above listed address, which is where the above work is being done. I understand that Triple Service Inc. will not provide an itemized breakdown of materials & labor beyond the price set forth above. Unless prior authorization is made in advance, payment for all work done is due upon completion. An office billing charge and/or finance charge of 2% per month will be applied to any overdue amounts. I agree to pay reasonable attorney's fees, court costs, and collection fees in the event of legal action. I have read this contract and agree to be bound by the terms contained herein. All old parts will be removed from the premises and discarded unless otherwise specified herein. ",
              acknowledgementParagraph: "I acknowledge satisfactory completion of the above described work and that the premises have been left in a satisfactory condition. I understand that if my check is not cleared, I am liable for the check and any charges from the bank in the event that collection efforts are initiated against me. I shall pay for all associated fees at the posted rates as well as all attorneys fees and collection costs. I agree that the amount of (Total) is the total flat price I have agreed to pay. \n\n"
            },
            royaltySentOn: nil,
            royaltyStatus: "Pending",
            adjustmentToId: nil,
            purchaseOrders: [
            ],
            commissionEligibilityDate: nil
          },
          summary: "17 year old forced air furnace is making a loud screeching noise like metal on metal. I offered a Monday appt since they have heat but they insisted on today. \n\n\n**aware of after hours SF \n",
          campaign: {
            id: 26466645,
            name: "Club Member",
            active: true,
            category: {
              id: 352,
              name: "Branding/Local Store Marketing",
              active: true
            },
            createdOn: "2021-09-10T12:52:59.6353059",
            modifiedOn: "2023-01-12T16:36:15.2765154"
          },
          customer: {
            id: 3182411,
            name: "Steve & Carole Dancey",
            type: "Residential",
            email: "c.dancey@comcast.net",
            active: true,
            address: {
              zip: "61342",
              city: "Mendota",
              unit: nil,
              state: "IL",
              street: "903 West Lawn Avenue",
              country: "USA",
              latitude: 41.5503968,
              longitude: -89.1338237,
              streetAddress: "903 West Lawn Avenue"
            },
            balance: 81.0,
            contacts: [
              {
                id: 3203932,
                memo: "home",
                type: "Phone",
                value: "8155396039",
                active: true,
                modifiedOn: "2020-09-16T15:07:47.4038704"
              },
              {
                id: 3206446,
                memo: "Carol",
                type: "Phone",
                value: "8158661149",
                active: true,
                modifiedOn: "2020-09-16T15:07:47.466385"
              },
              {
                id: 3206447,
                memo: "Steve",
                type: "Phone",
                value: "8158661150",
                active: true,
                modifiedOn: "2020-09-16T15:07:47.4989343"
              },
              {
                id: 3209216,
                memo: "Email",
                type: "Email",
                value: "c.dancey@comcast.net",
                active: true,
                modifiedOn: "2020-10-30T21:41:57.4737634"
              }
            ],
            importId: "103404",
            createdBy: nil,
            createdOn: "0001-01-01T00:00:00",
            doNotMail: false,
            modifiedOn: "2023-02-11T16:32:26.0227937",
            memberships: [
              {
                id: 3596009,
                to: nil,
                from: "2016-11-16T00:00:00",
                type: {
                  id: 1418883,
                  name: "CE-03 Monthly",
                  active: false
                },
                active: true,
                status: "Canceled",
                locationId: 3189766
              },
              {
                id: 3598080,
                to: nil,
                from: "2006-08-29T00:00:00",
                type: {
                  id: 1418888,
                  name: "GOLD2 Monthly",
                  active: false
                },
                active: true,
                status: "Canceled",
                locationId: 3189766
              }
            ],
            hasActiveMembership: true
          },
          duration: 7200.0,
          leadCall: nil,
          location: {
            id: 3189766,
            name: "Steve & Carole Dancey",
            zone: {
              id: 2024407,
              name: "Zone 1",
              zips: [
                "61342",
                "61371",
                "61372"
              ],
              active: true,
              cities: [
                "Mendota",
                "Triumph ",
                "Troy Grove"
              ],
              locnNumbers: [
              ],
              territoryNumbers: [
              ]
            },
            email: "c.dancey@comcast.net",
            active: true,
            address: {
              zip: "61342",
              city: "Mendota",
              unit: nil,
              state: "IL",
              street: "903 West Lawn Avenue",
              country: "USA",
              latitude: 41.5503968,
              longitude: -89.1338237,
              streetAddress: "903 West Lawn Avenue"
            },
            contacts: [
              {
                id: 3217275,
                memo: "home",
                type: "Phone",
                value: "8155396039",
                active: true,
                modifiedOn: "2020-09-16T15:07:47.4000775"
              },
              {
                id: 3219863,
                memo: "Carol",
                type: "Phone",
                value: "8158661149",
                active: true,
                modifiedOn: "2020-09-16T15:07:47.4662628"
              },
              {
                id: 3219864,
                memo: "Steve",
                type: "Phone",
                value: "8158661150",
                active: true,
                modifiedOn: "2020-09-16T15:07:47.4987545"
              },
              {
                id: 3222693,
                memo: "Email",
                type: "Email",
                value: "c.dancey@comcast.net",
                active: true,
                modifiedOn: "2020-10-30T21:41:57.4737634"
              }
            ],
            customer: {
              id: 3182411,
              name: "Steve & Carole Dancey",
              type: "Residential",
              email: "c.dancey@comcast.net",
              active: true,
              address: {
                zip: "61342",
                city: "Mendota",
                unit: nil,
                state: "IL",
                street: "903 West Lawn Avenue",
                country: "USA",
                latitude: 41.5503968,
                longitude: -89.1338237,
                streetAddress: "903 West Lawn Avenue"
              },
              balance: nil,
              contacts: [
                {
                  id: 3203932,
                  memo: "home",
                  type: "Phone",
                  value: "8155396039",
                  active: true,
                  modifiedOn: "2020-09-16T15:07:47.4038704"
                },
                {
                  id: 3206446,
                  memo: "Carol",
                  type: "Phone",
                  value: "8158661149",
                  active: true,
                  modifiedOn: "2020-09-16T15:07:47.466385"
                },
                {
                  id: 3206447,
                  memo: "Steve",
                  type: "Phone",
                  value: "8158661150",
                  active: true,
                  modifiedOn: "2020-09-16T15:07:47.4989343"
                },
                {
                  id: 3209216,
                  memo: "Email",
                  type: "Email",
                  value: "c.dancey@comcast.net",
                  active: true,
                  modifiedOn: "2020-10-30T21:41:57.4737634"
                }
              ],
              importId: "103404",
              createdBy: nil,
              createdOn: "0001-01-01T00:00:00",
              doNotMail: false,
              modifiedOn: "2023-02-11T16:32:26.0227937",
              memberships: [
                {
                  id: 3596009,
                  to: nil,
                  from: "2016-11-16T00:00:00",
                  type: {
                    id: 1418883,
                    name: "CE-03 Monthly",
                    active: false
                  },
                  active: true,
                  status: "Canceled",
                  locationId: 3189766
                },
                {
                  id: 3598080,
                  to: nil,
                  from: "2006-08-29T00:00:00",
                  type: {
                    id: 1418888,
                    name: "GOLD2 Monthly",
                    active: false
                  },
                  active: true,
                  status: "Canceled",
                  locationId: 3189766
                }
              ],
              customFields: [
                {
                  name: "Alt Name",
                  value: "",
                  typeId: 1008960
                }
              ],
              doNotService: false,
              phoneSettings: [
                {
                  doNotText: false,
                  phoneNumber: "8155396039"
                },
                {
                  doNotText: false,
                  phoneNumber: "8158661149"
                },
                {
                  doNotText: false,
                  phoneNumber: "8158661150"
                }
              ],
              hasActiveMembership: true
            },
            createdBy: nil,
            createdOn: "0001-01-01T00:00:00"
          },
          noCharge: false,
          createdBy: {
            id: 44743648,
            name: "Jade Price ",
            role: "CSR",
            email: "tripleservicecsr@gmail.com",
            active: true,
            loginName: "Jade11",
            modifiedOn: "2023-02-03T21:38:33.357153",
            phoneNumber: "8156159233108",
            customFields: [
            ],
            businessUnitId: nil
          },
          createdOn: "2023-02-11T16:20:24.6252105",
          estimates: [
            {
              id: 51337319,
              name: "$149 after hours",
              items: [
                {
                  id: 51339366,
                  qty: 1.0,
                  sku: {
                    id: 9287509,
                    name: "Safety Concern",
                    type: "Service",
                    soldHours: 0.0,
                    modifiedOn: "2021-12-30T19:23:30.2498505",
                    displayName: "Safety Concern",
                    generalLedgerAccountId: 8994734,
                    generalLedgerAccountName: "Sales"
                  },
                  tax: 0.0,
                  type: 0,
                  total: 0.0,
                  subtotal: 0.0,
                  unitRate: 0.0,
                  modifiedOn: "2023-02-11T18:43:37.2311427",
                  skuAccount: "Sales",
                  description: "Safety Concern",
                  membershipTypeId: nil
                }
              ],
              jobId: 51340759,
              soldOn: "2023-02-11T18:43:29.738",
              status: {
                name: "Sold",
                value: 1
              },
              summary: "",
              jobNumber: "51340759",
              modifiedOn: "2023-02-11T18:43:37.5733039",
              externalLinks: [
              ]
            },
            {
              id: 51337710,
              name: "Inducer motor",
              items: [
                {
                  id: 51337312,
                  qty: 1.0,
                  sku: {
                    id: 1055953,
                    name: "HT1176",
                    type: "Service",
                    soldHours: 0.9,
                    modifiedOn: "2022-01-16T19:35:39.9967558",
                    displayName: "Replace Induced Draft Motor Single Or Two Stage 90% - Stock",
                    generalLedgerAccountId: 8994734,
                    generalLedgerAccountName: "Sales"
                  },
                  tax: 0.0,
                  type: 0,
                  total: 554.99,
                  subtotal: 0.0,
                  unitRate: 554.99,
                  modifiedOn: "2023-02-11T17:56:36.9872861",
                  skuAccount: "Sales",
                  description: "Replace Induced Draft Motor Single Or Two Stage 90% - Stock.<br/>May not cover Trane, American Standard, Lennox, Carrier or Bryant Inducers",
                  membershipTypeId: nil
                }
              ],
              jobId: 51340759,
              soldOn: nil,
              status: {
                name: "Open",
                value: 0
              },
              summary: "",
              jobNumber: "51340759",
              modifiedOn: "2023-02-11T18:51:13.1313935",
              externalLinks: [
              ]
            }
          ],
          jobNumber: "51340759",
          jobStatus: "Completed",
          projectId: 0,
          webhookId: 51066458,
          controller: "integrations/servicetitan/integrations",
          externalId: nil,
          modifiedOn: "2023-02-11T18:51:12.9671903",
          __eventInfo: {
            eventId: "2023-02-11T18:51:13.8312133Z",
            webhookId: 51066458,
            webhookType: "JobCompleted"
          },
          completedOn: "2023-02-11T18:51:07.698",
          scheduledOn: "2023-02-11T17:00:00",
          __tenantInfo: {
            id: 737513509,
            name: "tripleserviceinc"
          },
          businessUnit: {
            id: 1795,
            name: "HVAC - Service",
            email: "service@tripleserviceinc.com",
            active: true,
            tenant: {
              id: 737513509,
              name: "tripleserviceinc",
              modifiedOn: "2023-01-18T06:41:02.0638366",
              conceptCode: "NotSet"
            },
            address: {
              zip: "61342",
              city: "Mendota",
              unit: nil,
              state: "Illinois",
              street: "801 Monroe St",
              country: "United States"
            },
            currency: "USD",
            modifiedOn: "2022-10-06T12:36:44.7969959",
            conceptCode: "NotSet",
            phoneNumber: "(815) 539-3828",
            officialName: "Triple Service, Inc.",
            invoiceHeader: "Triple Service Inc\n801 Monroe St\nMendota, IL\n61342",
            defaultTaxRate: 0.0,
            invoiceMessage: "Thank you for your business!",
            quickbooksClass: nil,
            authorizationParagraph: "I, the undersigned, am the owner or authorized representative of the premises at the above listed address, which is where the above work is being done. I understand that Triple Service Inc. will not provide an itemized breakdown of materials & labor beyond the price set forth above. Unless prior authorization is made in advance, payment for all work done is due upon completion. An office billing charge and/or finance charge of 2% per month will be applied to any overdue amounts. I agree to pay reasonable attorney's fees, court costs, and collection fees in the event of legal action. I have read this contract and agree to be bound by the terms contained herein. All old parts will be removed from the premises and discarded unless otherwise specified herein. ",
            acknowledgementParagraph: "I acknowledge satisfactory completion of the above described work and that the premises have been left in a satisfactory condition. I understand that if my check is not cleared, I am liable for the check and any charges from the bank in the event that collection efforts are initiated against me. I shall pay for all associated fees at the posted rates as well as all attorneys fees and collection costs. I agree that the amount of (Total) is the total flat price I have agreed to pay. \n\n"
          },
          customFields: [
          ],
          historyItemId: 51337324,
          jobAssignments: [
            {
              id: 51340774,
              team: "Maintenance/Service",
              jobId: 51340759,
              split: 100.0,
              active: true,
              status: "Done",
              payType: 2,
              jobNumber: "51340759",
              assignedBy: {
                id: 44743648,
                name: "Jade Price ",
                modifiedOn: "2023-02-03T21:38:33.357153"
              },
              assignedOn: "2023-02-11T16:20:25.7567103",
              modifiedOn: "2023-02-11T18:51:12.8744968",
              technician: {
                id: 42918869,
                name: "Cameron Thomas",
                modifiedOn: "2023-02-11T16:51:48.9622877"
              },
              totalDrivingHours: 1260.0,
              totalWorkingHours: 5940.0
            }
          ],
          lastAppointment: {
            id: 51340760,
            end: "2023-02-11T19:00:00",
            start: "2023-02-11T17:00:00",
            status: "Done",
            duration: 7200.0,
            arrivalWindowEnd: "2023-02-11T19:00:00",
            appointmentNumber: "51340759-1",
            arrivalWindowStart: "2023-02-11T17:00:00"
          },
          appointmentCount: 1,
          arrivalWindowEnd: "2023-02-11T19:00:00",
          firstAppointment: {
            id: 51340760,
            end: "2023-02-11T19:00:00",
            start: "2023-02-11T17:00:00",
            status: "Done",
            duration: 7200.0,
            arrivalWindowEnd: "2023-02-11T19:00:00",
            appointmentNumber: "51340759-1",
            arrivalWindowStart: "2023-02-11T17:00:00"
          },
          arrivalWindowStart: "2023-02-11T17:00:00",
          manageEmployeeEmail: nil,
          manageFollowUpEmail: nil,
          notificationsEnabled: true,
          techGeneratedLeadSource: nil
        }
      end

      # example ServiceTitan jobrescheduled webhook
      def jobrescheduled_webhook_params
        {
          id: 299681090,
          end: "2023-02-11T21:00:00",
          tags: [
            {
              id: 299681102,
              name: "HPM",
              ownerId: 299681090
            },
            {
              id: 299681103,
              name: "HVAC 0-5 Years",
              ownerId: 299681090
            }
          ],
          type: {
            id: 230135847,
            name: "HVAC Maintenance",
            modifiedOn: "2023-02-02T15:27:08.9188594"
          },
          start: "2023-02-11T19:00:00",
          action: "endpoint",
          active: true,
          status: "Scheduled",
          booking: nil,
          eventId: "2023-02-11T18:49:28.2514101Z",
          history: [
            {
              id: 299681105,
              date: "2023-02-09T17:27:49.2410639",
              start: "2023-02-11T20:00:00",
              employee: {
                id: 208718284,
                name: "Melissa Avalos",
                role: "Dispatch",
                type: "Employee",
                email: "mavalos@bonney.com",
                active: true,
                loginName: "melissaa",
                modifiedOn: "2023-01-31T06:46:51.740778",
                phoneNumber: "2793560584",
                businessUnitId: nil
              },
              eventType: "Job Booked",
              usedSchedulingTool: 0
            }
          ],
          invoice: {
            id: 299681095,
            tax: 0.0,
            items: [
            ],
            jobId: 299681090,
            total: 0.0,
            active: true,
            number: "299681090",
            status: {
              name: "Pending",
              value: 0,
              depositedOn: nil
            },
            balance: 0.0,
            batchId: 0,
            summary: nil,
            payments: [
            ],
            subtotal: 0.0,
            batchName: nil,
            jobNumber: "299681090",
            customerId: 50383290,
            invoicedOn: nil,
            modifiedOn: "2023-02-09T17:27:49.7977775",
            batchNumber: 0,
            royaltyDate: nil,
            royaltyMemo: nil,
            businessUnit: {
              id: 36562,
              name: "HVAC Maintenance - Residential ",
              email: "info@bonney.com",
              active: true,
              tenant: {
                id: 215810824,
                name: "bonney",
                modifiedOn: "2023-01-31T06:46:50.9142557",
                conceptCode: "NotSet"
              },
              address: {
                zip: nil,
                city: nil,
                unit: nil,
                state: nil,
                street: nil,
                country: nil
              },
              currency: "USD",
              modifiedOn: "2023-02-02T15:27:08.9188374",
              conceptCode: "NotSet",
              phoneNumber: "(916) 444-0551",
              officialName: "Bonney Plumbing, Electrical, Heating & Air ",
              defaultTaxRate: 0.0,
              quickbooksClass: "1 - Sacramento:B - HVAC:Maintenance",
              authorizationParagraph: "I authorize Bonney, Plumbing, Heating, Air & Rooter Service to proceed with the diagnosis/scope of work at which rate I agree to pay upon completion.\nContract Price: {Total}\nApproximate Start Date: {ApproxStartDate}\t\nApproximate Completion Date: {ApproxEndDate}\t\n<strong>IT IS AGAINST THE LAW FOR A CONTRACTOR TO COLLECT PAYMENT FOR WORK NOT YET COMPLETED, OR FOR MATERIALS NOT YET DELIVERED. HOWEVER, A CONTRACTOR MAY REQUIRE A DOWN PAYMENT – MAY NOT EXCEED $1,000 OR 10% OF THE CONTRACT PRICE, WHICHEVER IS LESS. </strong>  \nWARRANTY: All materials supplied by Bonney Plumbing, Heating, Air & Rooter Service are covered by the Manufacturer’s warranty. Bonney’s workmanship and labor are guaranteed for six (6) months unless otherwise noted.\n<strong>The law requires that the contractor give you a notice explaining your right to cancel. By signing below, I certify the contractor has given me a ‘Notice of the Three-Day Right to Cancel.’</strong>  \nBy signing below, I certify that I am the Owner or the authorized agent of the premises listed herein. I have read and agree to the terms of this Agreement, including the section 17 on “Asbestos, Mold and Hazardous Substances” and any attached documents. {Terms}",
              acknowledgementParagraph: "I find the service and materials rendered and installed in connection with the work and any extra work (Change Order) mentioned in this Agreement to have been completed in a satisfactory manner. I agree that the amount set forth on this contract labeled “AMOUNT DUE” to be the total and complete price, unless otherwise noted - {Total}."
            },
            royaltySentOn: nil,
            royaltyStatus: "Pending",
            adjustmentToId: nil,
            purchaseOrders: [
            ],
            commissionEligibilityDate: nil
          },
          summary: "Time Frame: 12-7 \nBonney Beyond Exp: 4/2023 \nGate Code: None \nScheduling Requests / # to call wow: 916-204-6409 \nJob Summary: HPM \nNumber of systems: 1 \nYear system installed: 5 Years old \nSystem location: Garage \nHome Warranty: No \n\nPOA Authorization\n\nRental Properties\nCC on file auth to $500? ",
          campaign: {
            id: 105590148,
            name: "Direct & Other",
            active: true,
            category: nil,
            createdOn: "2020-03-31T22:27:00.8506509",
            modifiedOn: "2021-06-22T15:31:00.5192096"
          },
          customer: {
            id: 50383290,
            name: "Joe VanNote and Ylena Ashmarova",
            type: "Residential",
            email: "deva.76@hotmail.com",
            active: true,
            address: {
              zip: "95826",
              city: "Sacramento",
              unit: nil,
              state: "CA",
              street: "3931 Thornhill Drive",
              country: "USA",
              latitude: 38.542984,
              longitude: -121.36413800000003,
              streetAddress: "3931 Thornhill Drive"
            },
            balance: 0.0,
            contacts: [
              {
                id: 50383291,
                memo: nil,
                type: "MobilePhone",
                value: "9162046409",
                active: true,
                modifiedOn: "2022-07-11T22:13:28.6794463"
              },
              {
                id: 50383292,
                memo: nil,
                type: "Email",
                value: "deva.76@hotmail.com",
                active: true,
                modifiedOn: "2020-04-14T07:45:06.0975902"
              },
              {
                id: 63982124,
                memo: nil,
                type: "Email",
                value: "Suashmarova@yahoo.com",
                active: true,
                modifiedOn: "2019-11-14T10:01:26.5413498"
              },
              {
                id: 64076216,
                memo: nil,
                type: "Email",
                value: "Dove.76@hotmail.com",
                active: true,
                modifiedOn: "2019-11-14T10:01:26.5413498"
              }
            ],
            createdBy: 73322,
            createdOn: "2016-02-28T22:59:55.1733875",
            doNotMail: false,
            modifiedOn: "2023-01-15T11:32:36.8064925",
            memberships: [
              {
                id: 50389050,
                to: "2017-02-28T00:00:00",
                from: "2016-02-29T00:00:00",
                type: {
                  id: 46435,
                  name: "HISTORICAL BAM 1 YR",
                  active: false
                },
                active: false,
                status: "Deleted",
                locationId: 50383293
              },
              {
                id: 63980501,
                to: "2018-08-01T00:00:00",
                from: "2017-08-01T00:00:00",
                type: {
                  id: 46435,
                  name: "HISTORICAL BAM 1 YR",
                  active: false
                },
                active: false,
                status: "Deleted",
                locationId: 50383293
              }
            ],
            customFields: [
              {
                name: "USA (811) Confirmation Ticket #",
                value: "",
                typeId: 61059666
              },
              {
                name: "AR Notes:",
                value: "",
                typeId: 219943007
              }
            ],
            doNotService: false,
            phoneSettings: [
              {
                doNotText: false,
                phoneNumber: "9162046409"
              }
            ],
            hasActiveMembership: true
          },
          duration: 7200.0,
          leadCall: nil,
          location: {
            id: 50383293,
            name: "Phil VanNote and Ylena Ashmarova",
            zone: {
              id: 50031129,
              name: "Highway 50",
              zips: ["95667", "95670", "95672", "95682", "95762", "95662", "95628", "95630", "95742", "95623", "95655", "95827", "95826"],
              active: true,
              cities: ["Rancho", "Folsom", "Cameron Park", "Placerville", "El Dorado Hills", "Fair Oaks", "Orangevale", "Diamond Springs", "Mather"],
              locnNumbers: [
              ],
              territoryNumbers: [
              ]
            },
            email: "rosesforme15@gmail.com",
            active: true,
            address: {
              zip: "95826",
              city: "Sacramento",
              unit: nil,
              state: "CA",
              street: "3931 Thornhill Drive",
              country: "USA",
              latitude: 38.542984,
              longitude: -121.36413800000003,
              streetAddress: "3931 Thornhill Drive"
            },
            contacts: [
              {
                id: 50383294,
                memo: "O - Ylena ",
                type: "MobilePhone",
                value: "9162046409",
                active: true,
                modifiedOn: "2022-07-11T22:13:28.6795265"
              },
              {
                id: 50383755,
                memo: "Joe",
                type: "MobilePhone",
                value: "9162047331",
                active: true,
                modifiedOn: "2022-07-11T22:13:28.6824342"
              },
              {
                id: 105822628,
                memo: nil,
                type: "Email",
                value: "rosesforme15@gmail.com",
                active: true,
                modifiedOn: "2020-04-07T16:31:28.5382262"
              }
            ],
            customer: {
              id: 50383290,
              name: "Joe VanNote and Ylena Ashmarova",
              type: "Residential",
              email: "deva.76@hotmail.com",
              active: true,
              address: {
                zip: "95826",
                city: "Sacramento",
                unit: nil,
                state: "CA",
                street: "3931 Thornhill Drive",
                country: "USA",
                latitude: 38.542984,
                longitude: -121.36413800000003,
                streetAddress: "3931 Thornhill Drive"
              },
              balance: nil,
              contacts: [
                {
                  id: 50383291,
                  memo: nil,
                  type: "MobilePhone",
                  value: "9162046409",
                  active: true,
                  modifiedOn: "2022-07-11T22:13:28.6794463"
                },
                {
                  id: 50383292,
                  memo: nil,
                  type: "Email",
                  value: "deva.76@hotmail.com",
                  active: true,
                  modifiedOn: "2020-04-14T07:45:06.0975902"
                },
                {
                  id: 63982124,
                  memo: nil,
                  type: "Email",
                  value: "Suashmarova@yahoo.com",
                  active: true,
                  modifiedOn: "2019-11-14T10:01:26.5413498"
                },
                {
                  id: 64076216,
                  memo: nil,
                  type: "Email",
                  value: "Dove.76@hotmail.com",
                  active: true,
                  modifiedOn: "2019-11-14T10:01:26.5413498"
                }
              ],
              createdBy: 73322,
              createdOn: "2016-02-28T22:59:55.1733875",
              doNotMail: false,
              modifiedOn: "2023-01-15T11:32:36.8064925",
              memberships: [
                {
                  id: 50389050,
                  to: "2017-02-28T00:00:00",
                  from: "2016-02-29T00:00:00",
                  type: {
                    id: 46435,
                    name: "HISTORICAL BAM 1 YR",
                    active: false
                  },
                  active: false,
                  status: "Deleted",
                  locationId: 50383293
                },
                {
                  id: 63980501,
                  to: "2018-08-01T00:00:00",
                  from: "2017-08-01T00:00:00",
                  type: {
                    id: 46435,
                    name: "HISTORICAL BAM 1 YR",
                    active: false
                  },
                  active: false,
                  status: "Deleted",
                  locationId: 50383293
                }
              ],
              doNotService: false,
              phoneSettings: [
                {
                  doNotText: false,
                  phoneNumber: "9162046409"
                }
              ],
              hasActiveMembership: true
            },
            createdBy: 73322,
            createdOn: "2016-02-28T22:59:55.1743826",
            modifiedOn: "2022-12-16T01:18:31.4219992",
            customFields: [
              {
                name: "USA (811) Confirmation Ticket #",
                value: "",
                typeId: 61059666
              },
              {
                name: "AR Notes:",
                value: "",
                typeId: 219943007
              }
            ]
          },
          noCharge: false,
          createdBy: {
            id: 208718284,
            name: "Melissa Avalos",
            role: "Dispatch",
            email: "mavalos@bonney.com",
            active: true,
            loginName: "melissaa",
            modifiedOn: "2023-01-31T06:46:51.740778",
            phoneNumber: "2793560584",
            customFields: [
            ],
            businessUnitId: nil
          },
          createdOn: "2023-02-09T17:27:49.2410639",
          estimates: [
          ],
          jobNumber: "299681090",
          jobStatus: "Scheduled",
          projectId: 0,
          webhookId: 298011995,
          controller: "integrations/servicetitan/integrations",
          externalId: nil,
          modifiedOn: "2023-02-11T18:49:26.7891581",
          __eventInfo: {
            eventId: "2023-02-11T18:49:28.2514101Z",
            webhookId: 298011995,
            webhookType: "JobRescheduled"
          },
          completedOn: nil,
          rescheduled: true,
          scheduledOn: "2023-02-11T19:00:00",
          __tenantInfo: {
            id: 215810824,
            name: "bonney"
          },
          businessUnit: {
            id: 36562,
            name: "HVAC Maintenance - Residential ",
            email: "info@bonney.com",
            active: true,
            tenant: {
              id: 215810824,
              name: "bonney",
              modifiedOn: "2023-01-31T06:46:50.9142557",
              conceptCode: "NotSet"
            },
            address: {
              zip: nil,
              city: nil,
              unit: nil,
              state: nil,
              street: nil,
              country: nil
            },
            currency: "USD",
            modifiedOn: "2023-02-02T15:27:08.9188374",
            conceptCode: "NotSet",
            phoneNumber: "(916) 444-0551",
            officialName: "Bonney Plumbing, Electrical, Heating & Air ",
            defaultTaxRate: 0.0,
            quickbooksClass: "1 - Sacramento:B - HVAC:Maintenance",
            authorizationParagraph: "I authorize Bonney, Plumbing, Heating, Air & Rooter Service to proceed with the diagnosis/scope of work at which rate I agree to pay upon completion.\nContract Price: {Total}\nApproximate Start Date: {ApproxStartDate}\t\nApproximate Completion Date: {ApproxEndDate}\t\n<strong>IT IS AGAINST THE LAW FOR A CONTRACTOR TO COLLECT PAYMENT FOR WORK NOT YET COMPLETED, OR FOR MATERIALS NOT YET DELIVERED. HOWEVER, A CONTRACTOR MAY REQUIRE A DOWN PAYMENT – MAY NOT EXCEED $1,000 OR 10% OF THE CONTRACT PRICE, WHICHEVER IS LESS. </strong>  \nWARRANTY: All materials supplied by Bonney Plumbing, Heating, Air & Rooter Service are covered by the Manufacturer’s warranty. Bonney’s workmanship and labor are guaranteed for six (6) months unless otherwise noted.\n<strong>The law requires that the contractor give you a notice explaining your right to cancel. By signing below, I certify the contractor has given me a ‘Notice of the Three-Day Right to Cancel.’</strong>  \nBy signing below, I certify that I am the Owner or the authorized agent of the premises listed herein. I have read and agree to the terms of this Agreement, including the section 17 on “Asbestos, Mold and Hazardous Substances” and any attached documents. {Terms}",
            acknowledgementParagraph: "I find the service and materials rendered and installed in connection with the work and any extra work (Change Order) mentioned in this Agreement to have been completed in a satisfactory manner. I agree that the amount set forth on this contract labeled “AMOUNT DUE” to be the total and complete price, unless otherwise noted - {Total}."
          },
          customFields: [
            {
              name: "Job Scope",
              value: "",
              typeId: 18433
            },
            {
              name: "Cost Amount",
              value: "",
              typeId: 77818
            }
          ],
          historyItemId: 300129224,
          jobAssignments: [
            {
              id: 299937978,
              team: "HVAC 4 Luis M1",
              jobId: 299681090,
              split: 100.0,
              active: false,
              status: "Done",
              payType: 2,
              jobNumber: "299681090",
              assignedBy: {
                id: 217944178,
                name: "Brooke Steinke",
                modifiedOn: "2023-01-31T06:46:51.7462586"
              },
              assignedOn: "2023-02-10T18:58:43.5481788",
              modifiedOn: "2023-02-11T17:29:44.7036223",
              technician: {
                id: 250196965,
                name: "Nick Leota",
                modifiedOn: "2023-02-11T15:26:11.3340706"
              },
              totalDrivingHours: 0.0,
              totalWorkingHours: 0.0
            }
          ],
          lastAppointment: {
            id: 299681091,
            end: "2023-02-11T21:00:00",
            start: "2023-02-11T19:00:00",
            status: "Scheduled",
            duration: 7200.0,
            arrivalWindowEnd: "2023-02-12T03:00:00",
            appointmentNumber: "299681090-1",
            arrivalWindowStart: "2023-02-11T20:00:00"
          },
          appointmentCount: 1,
          arrivalWindowEnd: "2023-02-12T03:00:00",
          firstAppointment: {
            id: 299681091,
            end: "2023-02-11T21:00:00",
            start: "2023-02-11T19:00:00",
            status: "Scheduled",
            duration: 7200.0,
            arrivalWindowEnd: "2023-02-12T03:00:00",
            appointmentNumber: "299681090-1",
            arrivalWindowStart: "2023-02-11T20:00:00"
          },
          arrivalWindowStart: "2023-02-11T20:00:00",
          manageEmployeeEmail: true,
          manageFollowUpEmail: true,
          notificationsEnabled: true,
          techGeneratedLeadSource: nil
        }
      end

      # example ServiceTitan payment types
      [
        {:id=>54, :name=>"Cash", :modifiedOn=>"2023-02-14T18:58:16.0449069Z"},
        {:id=>56, :name=>"Check", :modifiedOn=>"2023-02-14T18:58:23.0853287Z"},
        {:id=>58, :name=>"Visa", :modifiedOn=>"2023-02-14T19:11:17.5513908Z"},
        {:id=>59, :name=>"MasterCard", :modifiedOn=>"2023-02-14T19:08:23.3395341Z"},
        {:id=>60, :name=>"AMEX", :modifiedOn=>"2023-02-14T18:53:18.7931275Z"},
        {:id=>61, :name=>"Discover", :modifiedOn=>"2023-02-14T18:59:59.6315769Z"},
        {:id=>62, :name=>"Refund by Check", :modifiedOn=>"2023-02-14T19:09:58.4159965Z"},
        {:id=>1025, :name=>"Financing Refund by Check", :modifiedOn=>"2023-02-14T19:00:59.7045922Z"},
        {:id=>1153, :name=>"Paypal", :modifiedOn=>"2023-02-14T19:09:21.4212376Z"},
        {:id=>10498, :name=>"GreenSky Financing", :modifiedOn=>"2023-02-14T19:08:11.8587071Z"},
        {:id=>21054283, :name=>"Wells Fargo Financing", :modifiedOn=>"2023-02-14T19:11:27.1072302Z"},
        {:id=>30381453, :name=>"Coupon Install 1st Payment", :modifiedOn=>"2019-06-28T09:40:06.9168097Z"},
        {:id=>30470993, :name=>"Bounced Check", :modifiedOn=>"2023-02-14T18:54:29.8281457Z"},
        {:id=>30479162, :name=>"Service Finance", :modifiedOn=>"2023-02-14T19:10:12.6508744Z"},
        {:id=>30907446, :name=>"Payment Correction", :modifiedOn=>"2019-06-28T09:40:06.9168097Z"},
        {:id=>30952165, :name=>"Red Brick Financing", :modifiedOn=>"2023-02-14T19:09:33.8332929Z"},
        {:id=>30959260, :name=>"Business Card Service $20", :modifiedOn=>"2023-02-14T18:58:08.0377284Z"},
        {:id=>31368031, :name=>"Credit Card Refund", :modifiedOn=>"2023-02-14T18:59:14.082456Z"},
        {:id=>31657964, :name=>"Coupon - MSC 1st Year Free", :modifiedOn=>"2023-02-14T18:58:32.6656401Z"},
        {:id=>31670741, :name=>"Trade", :modifiedOn=>"2023-02-14T19:11:10.3309133Z"},
        {:id=>33195458, :name=>"Tip for Technician", :modifiedOn=>"2023-02-14T19:10:49.8008239Z"},
        {:id=>33893708, :name=>"Bad Debt Write Off", :modifiedOn=>"2023-02-14T18:54:15.2791821Z"},
        {:id=>34654546, :name=>"Employee Tool Account", :modifiedOn=>"2023-02-14T19:00:09.260704Z"},
        {:id=>34698068, :name=>"Microf Financing", :modifiedOn=>"2023-02-14T19:08:35.5401116Z"},
        {:id=>36976847, :name=>"Finance Fee for Install Jobs", :modifiedOn=>"2023-02-14T19:00:29.9009974Z"},
        {:id=>36980534, :name=>"Finance Fee for Service Jobs", :modifiedOn=>"2023-02-14T19:00:38.8760213Z"},
        {:id=>56390460, :name=>"Gift of Heat Donation", :modifiedOn=>"2023-02-14T19:07:50.5571573Z"},
        {:id=>60867544, :name=>"Mobile Check Capture", :modifiedOn=>"2023-02-14T19:08:45.3149205Z"},
        {:id=>60874341, :name=>"ACH", :modifiedOn=>"2023-02-14T18:53:11.1429849Z"},
        {:id=>67264367, :name=>"Sunlight Finance", :modifiedOn=>"2023-02-14T19:10:39.2873074Z"},
        {:id=>69729244, :name=>"GreenSky Direct Funding", :modifiedOn=>"2023-02-14T19:08:00.2645698Z"},
        {:id=>71537236, :name=>"Online Payments", :modifiedOn=>"2023-02-14T19:09:03.0704457Z"}
      ]

      # example ServiceTitan customer model
      def st_customer_model
        {
          id: 0,
          active: true,
          name: "string",
          type: "Residential",
          address: {
            street: "string",
            unit: "string",
            city: "string",
            state: "string",
            zip: "string",
            country: "string",
            latitude: 0,
            longitude: 0
          },
          customFields: [{
            typeId: 0,
            name: "string",
            value: "string"
          }],
          balance: 0,
          doNotMail: true,
          doNotService: true,
          createdOn: "2022-06-08T14:58:33.473Z",
          createdById: 0,
          modifiedOn: "2022-06-08T14:58:33.473Z",
          mergedToId: 0
        }
      end

      # example ServiceTitan estimate model
      def st_estimate_model
        {
          id: 0,
          jobId: 0,
          projectId: 0,
          name: "string",
          jobNumber: "string",
          status: {
            value: 0,
            name: "string"
          },
          summary: "string",
          modifiedOn: "2022-06-08T14:58:33.473Z",
          soldOn: "2022-06-08T14:58:33.473Z",
          soldBy: 0,
          active: true,
          items: [{
            id: 0,
            sku: {
              id: 0,
              name: "string",
              displayName: "string",
              type: "string",
              soldHours: 0,
              generalLedgerAccountId: 0,
              generalLedgerAccountName: "string",
              modifiedOn: "2022-06-08T14:58:33.473Z"
            },
            skuAccount: "string",
            description: "string",
            qty: 0,
            unitRate: 0,
            total: 0,
            itemGroupName: "string",
            itemGroupRootId: 0,
            modifiedOn: "2022-06-08T14:58:33.473Z"
          }],
          externalLinks: [{
            name: "string",
            url: "string"
          }],
          subtotal: 0
        }
      end

      # example ServiceTitan job model
      def st_job_model
        {
          id: 0,
          jobNumber: "string",
          projectId: 0,
          customerId: 0,
          locationId: 0,
          jobStatus: "string",
          completedOn: "2022-06-08T14:58:33.473Z",
          businessUnitId: 0,
          jobTypeId: 0,
          priority: "string",
          campaignId: 0,
          summary: "string",
          customFields: [{
            typeId: 0,
            name: "string",
            value: "string"
          }],
          appointmentCount: 0,
          firstAppointmentId: 0,
          lastAppointmentId: 0,
          recallForId: 0,
          warrantyId: 0,
          jobGeneratedLeadSource: {
            jobId: 0,
            employeeId: 0
          },
          noCharge: true,
          notificationsEnabled: true,
          createdOn: "2022-06-08T14:58:33.473Z",
          createdById: 0,
          modifiedOn: "2022-06-08T14:58:33.473Z",
          tagTypeIds: [0],
          leadCallId: 0,
          bookingId: 0,
          soldById: 0,
          externalData: [{
            key: "string",
            value: "string"
          }]
        }
      end

      # example ServiceTitan techniciandispatched webhook params
      def techniciandispatched_webhook_params
        {
          id: 50888238,
          end: "2023-02-11T21:00:00",
          tags: [
            {
              id: 50888246,
              name: "Potential Member",
              ownerId: 50888238
            }
          ],
          type: {
            id: 1739292,
            name: "Residential Door Will Not Open",
            modifiedOn: "2022-05-26T18:08:02.0005786"
          },
          start: "2023-02-11T17:00:00",
          action: "endpoint",
          active: true,
          status: "Dispatched",
          booking: nil,
          eventId: "2023-02-11T18:51:08.3821088Z",
          history: [
            {
              id: 50888247,
              date: "2023-02-11T15:54:51.5884349",
              start: "2023-02-11T17:00:00",
              employee: {
                id: 49106606,
                name: "Kurt Brumfield",
                role: "Dispatch",
                type: "Employee",
                email: "kurtb@garagedoordoctorllc.com",
                active: true,
                loginName: "brumfieldk",
                modifiedOn: "2023-01-27T13:59:59.1053938",
                phoneNumber: "7655613523",
                businessUnitId: nil
              },
              eventType: "Job Booked",
              usedSchedulingTool: 0
            }
          ],
          invoice: {
            id: 50888242,
            tax: 0.0,
            items: [
            ],
            jobId: 50888238,
            total: 0.0,
            active: true,
            number: "50888238",
            status: {
              name: "Pending",
              value: 0,
              depositedOn: nil
            },
            balance: 0.0,
            batchId: 0,
            summary: nil,
            payments: [
            ],
            subtotal: 0.0,
            batchName: nil,
            jobNumber: "50888238",
            customerId: 50887319,
            invoicedOn: nil,
            modifiedOn: "2023-02-11T15:54:51.7093225",
            batchNumber: 0,
            royaltyDate: nil,
            royaltyMemo: nil,
            businessUnit: {
              id: 2179,
              name: "Residential Service Team",
              email: "info@garagedoordoctorllc.com",
              active: true,
              tenant: {
                id: 726004309,
                name: "garagedoordoctor",
                modifiedOn: "2023-02-08T04:07:53.3232482",
                conceptCode: "NotSet"
              },
              address: {
                zip: "46239",
                city: "Indianapolis",
                unit: nil,
                state: "Indiana",
                street: "1725 S. Franklin Road Suite B",
                country: "United States"
              },
              currency: "USD",
              modifiedOn: "2023-01-06T14:38:06.1286792",
              conceptCode: "NotSet",
              phoneNumber: "(317) 882-3667",
              officialName: "Garage Door Doctor ",
              invoiceHeader: "Garage Door Doctor \n1725 S. Franklin Road Suite B, Indianapolis, Indiana 46239 United States\n(317) 882-3667",
              defaultTaxRate: 0.0,
              invoiceMessage: "Thank you for choosing Garage Door Doctor ",
              quickbooksClass: "Residential Service Team",
              authorizationParagraph: "This invoice is agreed and acknowledged.  Payment is due upon receipt.  A service fee will be charged for any returned checks.  All past due amounts will be subject to a 3% per month late fees plus all attorney fees and collection agency.",
              acknowledgementParagraph: "I find and agree that all work performed by {BusinessUnitOfficialName} has been completed in a satisfactory and workmanlike manner. I have been given the opportunity to address concerns and/or discrepancies in the work provided, and I either have no such concerns or have found no discrepancies or they have been addressed to my satisfaction. My signature here signifies my full and final acceptance of all work performed by the contractor."
            },
            royaltySentOn: nil,
            royaltyStatus: "Pending",
            adjustmentToId: nil,
            purchaseOrders: [
            ],
            commissionEligibilityDate: nil
          },
          summary: "Says heard a loud bang and now he can only get door open 4 inches. Believes it is spring problem. Looking to just get to where he can manually open it not fix it.\n\n$79 fee waived with work done.\n\nCAH",
          campaign: {
            id: 4109180,
            name: "LSA",
            active: true,
            category: {
              id: 299,
              name: "PPC",
              active: true
            },
            createdOn: "2020-10-29T01:06:15.8045508",
            modifiedOn: "2022-11-18T11:01:16.8342931"
          },
          customer: {
            id: 50887319,
            name: "Justin Ford",
            type: "Residential",
            email: "pitboss72@hotmail.com",
            active: true,
            address: {
              zip: "46038",
              city: "Fishers",
              unit: nil,
              state: "IN",
              street: "10011 Sapphire Berry Lane",
              country: "USA",
              latitude: 39.99976849999999,
              longitude: -85.9905967,
              streetAddress: "10011 Sapphire Berry Lane"
            },
            balance: 0.0,
            contacts: [
              {
                id: 50887321,
                memo: nil,
                type: "MobilePhone",
                value: "8177140585",
                active: true,
                modifiedOn: "2023-02-11T15:52:23.2134824"
              },
              {
                id: 50887322,
                memo: nil,
                type: "Email",
                value: "pitboss72@hotmail.com",
                active: true,
                modifiedOn: "2023-02-11T15:52:23.213811"
              }
            ],
            createdBy: 49106606,
            createdOn: "2023-02-11T15:52:23.2014055",
            doNotMail: false,
            modifiedOn: "2023-02-11T15:52:23.213849",
            memberships: [
            ],
            customFields: [
              {
                name: "source",
                value: "",
                typeId: 1796508
              },
              {
                name: "msclkid",
                value: "",
                typeId: 12514067
              }
            ],
            doNotService: false,
            phoneSettings: [
              {
                doNotText: false,
                phoneNumber: "8177140585"
              }
            ],
            hasActiveMembership: false
          },
          duration: 14400.0,
          leadCall: {
            id: 50889353,
            to: "3173494929",
            from: "8177140585",
            agent: {
              id: 49106606,
              name: "Kurt Brumfield",
              externalId: nil
            },
            reason: nil,
            callType: "Booked",
            campaign: {
              id: 4109180,
              name: "LSA",
              active: true,
              category: {
                id: 299,
                name: "PPC",
                active: true
              },
              createdOn: "2020-10-29T01:06:15.8045508",
              modifiedOn: "2022-11-18T11:01:16.8342931"
            },
            customer: {
              id: 50887319,
              name: "Justin Ford",
              type: "Residential",
              email: "pitboss72@hotmail.com",
              active: true,
              address: {
                zip: "46038",
                city: "Fishers",
                unit: nil,
                state: "IN",
                street: "10011 Sapphire Berry Lane",
                country: "USA",
                latitude: 39.99976849999999,
                longitude: -85.9905967,
                streetAddress: "10011 Sapphire Berry Lane"
              },
              balance: nil,
              contacts: [
                {
                  id: 50887321,
                  memo: nil,
                  type: "MobilePhone",
                  value: "8177140585",
                  active: true,
                  modifiedOn: "2023-02-11T15:52:23.2134824"
                },
                {
                  id: 50887322,
                  memo: nil,
                  type: "Email",
                  value: "pitboss72@hotmail.com",
                  active: true,
                  modifiedOn: "2023-02-11T15:52:23.213811"
                }
              ],
              createdBy: 49106606,
              createdOn: "2023-02-11T15:52:23.2014055",
              doNotMail: false,
              modifiedOn: "2023-02-11T15:52:23.213849",
              memberships: [
              ],
              customFields: [
                {
                  name: "source",
                  value: "",
                  typeId: 1796508
                },
                {
                  name: "msclkid",
                  value: "",
                  typeId: 12514067
                }
              ],
              doNotService: false,
              phoneSettings: [
                {
                  doNotText: false,
                  phoneNumber: "8177140585"
                }
              ],
              hasActiveMembership: false
            },
            duration: "00:05:12",
            createdBy: nil,
            direction: "Inbound",
            modifiedOn: "2023-02-11T15:54:51.7968555",
            receivedOn: "2023-02-11T15:47:16.38443",
            recordingUrl: "https://go.servicetitan.com/Call/CallRecording/50889353",
            voiceMailUrl: nil
          },
          location: {
            id: 50887324,
            name: "Justin Ford",
            email: "pitboss72@hotmail.com",
            active: true,
            address: {
              zip: "46038",
              city: "Fishers",
              unit: nil,
              state: "IN",
              street: "10011 Sapphire Berry Lane",
              country: "USA",
              latitude: 39.99976849999999,
              longitude: -85.9905967,
              streetAddress: "10011 Sapphire Berry Lane"
            },
            contacts: [
              {
                id: 50887325,
                memo: nil,
                type: "MobilePhone",
                value: "8177140585",
                active: true,
                modifiedOn: "2023-02-11T15:52:23.2860214"
              },
              {
                id: 50887326,
                memo: nil,
                type: "Email",
                value: "pitboss72@hotmail.com",
                active: true,
                modifiedOn: "2023-02-11T15:52:23.2863333"
              }
            ],
            customer: {
              id: 50887319,
              name: "Justin Ford",
              type: "Residential",
              email: "pitboss72@hotmail.com",
              active: true,
              address: {
                zip: "46038",
                city: "Fishers",
                unit: nil,
                state: "IN",
                street: "10011 Sapphire Berry Lane",
                country: "USA",
                latitude: 39.99976849999999,
                longitude: -85.9905967,
                streetAddress: "10011 Sapphire Berry Lane"
              },
              balance: nil,
              contacts: [
                {
                  id: 50887321,
                  memo: nil,
                  type: "MobilePhone",
                  value: "8177140585",
                  active: true,
                  modifiedOn: "2023-02-11T15:52:23.2134824"
                },
                {
                  id: 50887322,
                  memo: nil,
                  type: "Email",
                  value: "pitboss72@hotmail.com",
                  active: true,
                  modifiedOn: "2023-02-11T15:52:23.213811"
                }
              ],
              createdBy: 49106606,
              createdOn: "2023-02-11T15:52:23.2014055",
              doNotMail: false,
              modifiedOn: "2023-02-11T15:52:23.213849",
              memberships: [
              ],
              customFields: [
                {
                  name: "source",
                  value: "",
                  typeId: 1796508
                },
                {
                  name: "msclkid",
                  value: "",
                  typeId: 12514067
                }
              ],
              doNotService: false,
              phoneSettings: [
                {
                  doNotText: false,
                  phoneNumber: "8177140585"
                }
              ],
              hasActiveMembership: false
            },
            createdBy: 49106606,
            createdOn: "2023-02-11T15:52:23.2505874",
            equipment: [
            ],
            modifiedOn: "2023-02-11T15:52:23.2863662",
            customFields: [
            ]
          },
          noCharge: false,
          createdBy: {
            id: 49106606,
            name: "Kurt Brumfield",
            role: "Dispatch",
            email: "kurtb@garagedoordoctorllc.com",
            active: true,
            loginName: "brumfieldk",
            modifiedOn: "2023-01-27T13:59:59.1053938",
            phoneNumber: "7655613523",
            customFields: [
            ],
            businessUnitId: nil
          },
          createdOn: "2023-02-11T15:54:51.5884349",
          estimates: [
          ],
          jobNumber: "50888238",
          jobStatus: "InProgress",
          projectId: 0,
          webhookId: 47699975,
          controller: "integrations/servicetitan/integrations",
          externalId: nil,
          modifiedOn: "2023-02-11T18:51:07.7334935",
          __eventInfo: {
            eventId: "2023-02-11T18:51:08.3821088Z",
            webhookId: 47699975,
            webhookType: "TechnicianDispatched"
          },
          completedOn: nil,
          scheduledOn: "2023-02-11T17:00:00",
          __tenantInfo: {
            id: 726004309,
            name: "garagedoordoctor"
          },
          businessUnit: {
            id: 2179,
            name: "Residential Service Team",
            email: "info@garagedoordoctorllc.com",
            active: true,
            tenant: {
              id: 726004309,
              name: "garagedoordoctor",
              modifiedOn: "2023-02-08T04:07:53.3232482",
              conceptCode: "NotSet"
            },
            address: {
              zip: "46239",
              city: "Indianapolis",
              unit: nil,
              state: "Indiana",
              street: "1725 S. Franklin Road Suite B",
              country: "United States"
            },
            currency: "USD",
            modifiedOn: "2023-01-06T14:38:06.1286792",
            conceptCode: "NotSet",
            phoneNumber: "(317) 882-3667",
            officialName: "Garage Door Doctor ",
            invoiceHeader: "Garage Door Doctor \n1725 S. Franklin Road Suite B, Indianapolis, Indiana 46239 United States\n(317) 882-3667",
            defaultTaxRate: 0.0,
            invoiceMessage: "Thank you for choosing Garage Door Doctor ",
            quickbooksClass: "Residential Service Team",
            authorizationParagraph: "This invoice is agreed and acknowledged.  Payment is due upon receipt.  A service fee will be charged for any returned checks.  All past due amounts will be subject to a 3% per month late fees plus all attorney fees and collection agency.",
            acknowledgementParagraph: "I find and agree that all work performed by {BusinessUnitOfficialName} has been completed in a satisfactory and workmanlike manner. I have been given the opportunity to address concerns and/or discrepancies in the work provided, and I either have no such concerns or have found no discrepancies or they have been addressed to my satisfaction. My signature here signifies my full and final acceptance of all work performed by the contractor."
          },
          customFields: [
            {
              name: "Service Fee",
              value: "$79 Service Fee waived with paid repair",
              typeId: 14552199
            },
            {
              name: "Load Date",
              value: "",
              typeId: 39567369
            }
          ],
          historyItemId: 50895269,
          jobAssignments: [
            {
              id: 50888249,
              team: "2 Residential Service ",
              jobId: 50888238,
              split: 100.0,
              active: true,
              status: "Dispatched",
              payType: 2,
              jobNumber: "50888238",
              assignedBy: {
                id: 49106606,
                name: "Kurt Brumfield",
                modifiedOn: "2023-01-27T13:59:59.1053938"
              },
              assignedOn: "2023-02-11T15:54:51.8785798",
              modifiedOn: "2023-02-11T18:51:07.6342283",
              technician: {
                id: 41897119,
                name: "William Tewell",
                modifiedOn: "2023-02-11T18:51:07.747393"
              },
              totalDrivingHours: 0.0,
              totalWorkingHours: 0.0
            }
          ],
          lastAppointment: {
            id: 50888239,
            end: "2023-02-11T21:00:00",
            start: "2023-02-11T17:00:00",
            status: "Dispatched",
            duration: 14400.0,
            arrivalWindowEnd: "2023-02-11T21:00:00",
            appointmentNumber: "50888238-1",
            arrivalWindowStart: "2023-02-11T17:00:00"
          },
          appointmentCount: 1,
          arrivalWindowEnd: "2023-02-11T21:00:00",
          firstAppointment: {
            id: 50888239,
            end: "2023-02-11T21:00:00",
            start: "2023-02-11T17:00:00",
            status: "Dispatched",
            duration: 14400.0,
            arrivalWindowEnd: "2023-02-11T21:00:00",
            appointmentNumber: "50888238-1",
            arrivalWindowStart: "2023-02-11T17:00:00"
          },
          arrivalWindowStart: "2023-02-11T17:00:00",
          manageEmployeeEmail: nil,
          manageFollowUpEmail: nil,
          notificationsEnabled: true,
          techGeneratedLeadSource: nil
        }
      end
    end
  end
end
