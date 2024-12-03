# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/memberships/membership_events_by_contact.rb
module Integrations
  module Servicetitan
    module V2
      module Memberships
        class EventsByContactJob < ApplicationJob
          # Step #4: trigger events for membership expirations for a Contact
          # Integrations::Servicetitan::V2::Memberships::EventsByContactJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Memberships::EventsByContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_membership_events_by_contact').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) client_id:            (Integer)
          #   (req) contact_id:           (Integer)
          #   (req) st_membership_models: (Integer)
          def perform(**args)
            super

            return unless args.dig(:client_id).to_i.positive? && args.dig(:contact_id).to_i.positive? &&
                          args.dig(:st_membership_models).is_a?(Array) && args[:st_membership_models].present? &&
                          (contact = Contact.find_by(id: args[:contact_id].to_i)) &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                          (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) &&
                          st_model.valid_credentials? &&
                          (client_api_integration_mrse = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: 'membership_recurring_service_events'))

            # scan through each unique location_id/membership_type_id combo
            args[:st_membership_models].pluck(:locationId, :membershipTypeId).uniq.each do |location_id, membership_type_id|
              # scan through each active membership for a location_id/membership_type_id combo
              (location_st_membership_models = args[:st_membership_models].select { |st02| st02[:locationId] == location_id && st02[:membershipTypeId] == membership_type_id }.sort_by { |st03| Chronic.parse(st03) || 10.years.ago }.reverse).each do |location_st_membership_model|
                # check expiring ServiceTitan memberships
                # skip if "to" date is blank
                if location_st_membership_model.dig(:to).present?

                  # scan through each defined "membership_expiration" event
                  client_api_integration.events.deep_symbolize_keys.select { |_key, values| values[:action_type] == 'membership_expiration' && values[:campaign_id].positive? }.each_value do |event|
                    # skip (don't stop Campaigns) if this membership type is not included in the event's "stop" membership types selected or no "stop" membership types are selected
                    next if event.dig(:membership_types_stop).present? && event.dig(:membership_types_stop).exclude?(location_st_membership_model.dig(:membershipTypeId))
                    # skip (don't stop Campaigns) if ("to" - today) <= event.membership_days_prior)
                    next if ((Chronic.parse(location_st_membership_model.dig(:to)) - Time.current) / 24 / 60 / 60).round <= event.dig(:membership_days_prior).to_i

                    # look for a running Campaign assigned to the event for that location_id/membership_type_id or no location_id/membership_type_id and stop it
                    contact.contact_campaigns.left_joins(:delayed_jobs).where(campaign_id: event[:campaign_id], completed: false).where('contact_campaigns.data ILIKE ?', "%contact_location_id: #{location_id}%").where('contact_campaigns.data ILIKE ?', "%contact_membership_type_id: #{membership_type_id}%")
                           .or(contact.contact_campaigns.left_joins(:delayed_jobs).where(campaign_id: event[:campaign_id], completed: false).where.not('contact_campaigns.data ILIKE ?', '%contact_location_id:%').where.not('contact_campaigns.data ILIKE ?', '%contact_membership_type_id:%'))
                           .or(contact.contact_campaigns.left_joins(:delayed_jobs).where(campaign_id: event[:campaign_id], completed: true).where('contact_campaigns.data ILIKE ?', "%contact_location_id: #{location_id}%").where('contact_campaigns.data ILIKE ?', "%contact_membership_type_id: #{membership_type_id}%").where.not(delayed_jobs: { id: nil }))
                           .or(contact.contact_campaigns.left_joins(:delayed_jobs).where(campaign_id: event[:campaign_id], completed: true).where.not('contact_campaigns.data ILIKE ?', '%contact_location_id:%').where.not('contact_campaigns.data ILIKE ?', '%contact_membership_type_id:%').where.not(delayed_jobs: { id: nil }))
                           .uniq.each(&:stop)
                  end

                  # only process actions for the first membership with a "to" date present
                  if location_st_membership_model[:id] == location_st_membership_models.first[:id]
                    Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
                      action_type:           'membership_expiration',
                      contact_id:            contact.id,
                      business_unit_id:      location_st_membership_model.dig(:businessUnitId),
                      location_id:,
                      membership_days_prior: ((Chronic.parse(location_st_membership_model.dig(:to)) - Time.current) / 24 / 60 / 60).round,
                      st_membership_id:      location_st_membership_model.dig(:id),
                      membership_type_id:    location_st_membership_model.dig(:membershipTypeId)
                    )
                  end
                end

                # check ServiceTitan recurring service events
                recurring_event = client_api_integration_mrse.data.find { |mrse| mrse['membershipId'] == location_st_membership_model.dig(:id).to_i }&.deep_symbolize_keys

                next if recurring_event.blank?

                Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
                  action_type:             'membership_service_event',
                  contact_id:              contact.id,
                  business_unit_id:        location_st_membership_model.dig(:businessUnitId),
                  membership_days_prior:   recurring_event.dig(:date).present? ? ((Chronic.parse(recurring_event[:date]) - Time.current) / 24 / 60 / 60).round : nil,
                  st_membership_id:        location_st_membership_model.dig(:id),
                  membership_type_id:      location_st_membership_model.dig(:membershipTypeId),
                  membership_event_status: recurring_event.dig(:status)
                )
              end
            end
          end
          # example: st_membership_model
          # {
          #   :id=>85486172,
          #   :createdOn=>"2023-04-04T20:30:36.1576344Z",
          #   :createdById=>2305,
          #   :modifiedOn=>"2023-04-04T20:30:36.9580348Z",
          #   :followUpOn=>"0001-01-01T00:00:00Z",
          #   :cancellationDate=>nil,
          #   :from=>"2023-04-04T00:00:00Z",
          #   :nextScheduledBillDate=>nil,
          #   :to=>"2024-04-03T00:00:00Z",
          #   :billingFrequency=>"OneTime",
          #   :renewalBillingFrequency=>nil,
          #   :status=>"Active",
          #   :followUpStatus=>"NotAttempted",
          #   :active=>true,
          #   :initialDeferredRevenue=>0.0,
          #   :duration=>12,
          #   :renewalDuration=>nil,
          #   :businessUnitId=>57156666,
          #   :customerId=>11319291,
          #   :membershipTypeId=>10102828,
          #   :activatedById=>2305,
          #   :activatedFromId=>85486171,
          #   :billingTemplateId=>nil,
          #   :cancellationBalanceInvoiceId=>nil,
          #   :cancellationInvoiceId=>nil,
          #   :followUpCustomStatusId=>nil,
          #   :locationId=>11345865,
          #   :paymentMethodId=>nil,
          #   :paymentTypeId=>nil,
          #   :recurringLocationId=>11345865,
          #   :renewalMembershipTaskId=>45368116,
          #   :renewedById=>nil,
          #   :soldById=>2305,
          #   :customerPo=>nil,
          #   :importId=>nil,
          #   :memo=>nil
          # }

          # example: recurring_events
          # [
          #   {
          #     id:                           40_144_787,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'Won',
          #     date:                         '2018-02-01T00:00:00Z',
          #     createdOn:                    '2018-02-01T22:33:32.0273622Z',
          #     jobId:                        40_143_949,
          #     createdById:                  1_297_274,
          #     modifiedOn:                   '2022-09-30T05:25:14.8633333Z'
          #   },
          #   {
          #     id:                           70_177_781,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'Won',
          #     date:                         '2021-07-01T00:00:00Z',
          #     createdOn:                    '2020-07-01T00:50:26.2337908Z',
          #     jobId:                        100_409_354,
          #     createdById:                  nil,
          #     modifiedOn:                   '2022-09-30T05:25:14.8633333Z'
          #   },
          #   {
          #     id:                           178_966_660,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'Won',
          #     date:                         '2023-10-01T00:00:00Z',
          #     createdOn:                    '2022-10-02T03:04:12.7380349Z',
          #     jobId:                        229_885_955,
          #     createdById:                  nil,
          #     modifiedOn:                   '2023-09-18T21:41:27.0312798Z'
          #   },
          #   {
          #     id:                           189_382_701,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'Won',
          #     date:                         '2024-01-01T00:00:00Z',
          #     createdOn:                    '2023-01-02T07:41:08.7882785Z',
          #     jobId:                        235_361_012,
          #     createdById:                  nil,
          #     modifiedOn:                   '2023-12-19T20:35:06.315631Z'
          #   },
          #   {
          #     id:                           207_261_155,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'NotAttempted',
          #     date:                         '2024-04-01T00:00:00Z',
          #     createdOn:                    '2023-04-02T02:26:53.5444763Z',
          #     jobId:                        nil,
          #     createdById:                  nil,
          #     modifiedOn:                   '2023-04-02T02:26:53.5444763Z'
          #   },
          #   {
          #     id:                           218_122_516,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'NotAttempted',
          #     date:                         '2024-07-01T00:00:00Z',
          #     createdOn:                    '2023-07-02T01:21:06.7064715Z',
          #     jobId:                        nil,
          #     createdById:                  nil,
          #     modifiedOn:                   '2023-07-02T01:21:06.7064715Z'
          #   },
          #   {
          #     id:                           230_719_715,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'NotAttempted',
          #     date:                         '2024-10-01T00:00:00Z',
          #     createdOn:                    '2023-10-02T01:27:22.4792368Z',
          #     jobId:                        nil,
          #     createdById:                  nil,
          #     modifiedOn:                   '2023-10-02T01:27:22.4792368Z'
          #   },
          #   {
          #     id:                           236_064_116,
          #     locationRecurringServiceId:   40_144_784,
          #     locationRecurringServiceName: 'Quarterly Maintenance',
          #     membershipId:                 nil,
          #     membershipName:               nil,
          #     status:                       'NotAttempted',
          #     date:                         '2025-01-01T00:00:00Z',
          #     createdOn:                    '2024-01-02T01:14:12.6010492Z',
          #     jobId:                        nil,
          #     createdById:                  nil,
          #     modifiedOn:                   '2024-01-02T01:14:12.6010492Z'
          #   }
          # ]
        end
      end
    end
  end
end
