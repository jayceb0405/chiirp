# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/calls/call_completed_webhook_job.rb
module Integrations
  module Servicetitan
    module V2
      module Calls
        class CallCompletedWebhookJob < ApplicationJob
          # process ServiceTitan callcompleted webhooks
          # Integrations::Servicetitan::V2::Calls::CallCompletedWebhookJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Calls::CallCompletedWebhookJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'servicetitan_update_contact_webhook').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:   (Integer / default: nil)
          #   (req) customer:    (Hash / default: nil)
          #      ~ or ~
          #   (req) from:        (String / default: nil)
          #
          #   (opt) callType:    (String / default: nil)
          #   (opt) campaign:    (Hash / default: nil)
          #   (opt) direction:   (String / default: nil)
          #   (opt) duration:    (String / default: nil)
          #   (opt) id:          (Integer / default: nil)
          #   (opt) reason:      (Hash / default: nil)
          def perform(**args)
            super

            return unless (args.dig(:customer).present? || args.dig(:from).to_s.present?) &&
                          args.dig(:client_id).to_i.positive? && (client = Client.find_by(id: args[:client_id].to_i)) &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: client.id, target: 'servicetitan', name: '')) &&
                          (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials?

            args[:customer] = args.dig(:customer) || { name: 'Friend', contacts: [{ type: 'mobilephone', value: args.dig(:from).to_s }] }
            contact = st_model.update_contact_from_customer(st_customer_model: args[:customer])

            if contact&.valid?
              contact.raw_posts.create(ext_source: 'servicetitan', ext_id: 'callcompleted', data: args)

              if args.dig(:reason, :id).to_i.zero? && client_api_integration.call_event_delay.to_i.positive?
                st_call = st_model.call(st_call_id: args.dig(:id))

                if st_model.success? && st_call.present?
                  args[:callType]                       = st_call.dig(:callType)
                  args[:campaign_id]                    = st_call.dig(:campaign, :id)
                  args[:customer][:hasActiveMembership] = st_call.dig(:customer, :hasActiveMembership)
                  args[:customer][:type]                = st_call.dig(:customer, :type)
                  args[:duration]                       = st_call.dig(:duration)
                  args[:reason]                         = {} unless args.dig(:reason).is_a?(Hash)
                  args[:reason][:id]                    = st_call.dig(:reason, :id)
                end
              end
            else
              Rails.logger.info "Integrations::Servicetitan::V2::Calls::CallCompletedWebhookJob: #{{ client_id: client.id, contact_id: contact&.id, contact_errors: contact&.errors&.full_messages&.join(' '), contact: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
              return
            end

            Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
              contact_id:     contact.id,
              action_type:    'call_completed',
              call_direction: args.dig(:direction),
              call_duration:  (args.dig(:duration)&.split(':')&.first.to_i * (60 * 24)) + (args.dig(:duration)&.split(':')&.second.to_i * 60) + args.dig(:duration)&.split(':')&.third.to_i,
              call_reason_id: args.dig(:reason, :id),
              call_type:      args.dig(:callType),
              campaign_id:    args.dig(:campaign_id).presence || args.dig(:campaign, :id),
              campaign_name:  args.dig(:campaign, :name),
              customer_type:  args.dig(:customer, :type),
              membership:     args.dig(:customer, :hasActiveMembership),
              st_customer:    args.dig(:customer).present?
            )
          end
          # example args received with existing ST customer
          # {
          #   id:           72335191,
          #   to:           '7817896594',
          #   from:         '+17817677940',
          #   agent:        {
          #     id:         50826299,
          #     name:       'Hollie Senhaji',
          #     externalId: nil
          #   },
          #   action:       'endpoint',
          #   reason:       nil,
          #   eventId:      '2024-05-16T17:47:37.0523962Z',
          #   callType:     [nil, 'Abandoned', 'Booked', 'Excused', 'NotLead', 'Unbooked'],
          #   campaign:     {
          #                   category:     {"id"=>146, "name"=>"Social Media", "active"=>true},
          #                   source:       "Other",
          #                   otherSource:  "Nextdoor",
          #                   businessUnit: nil,
          #                   medium:       "Social",
          #                   otherMedium:  nil,
          #                   dnis:         "5303928776",
          #                   id:           20584755,
          #                   name:         "Nextdoor",
          #                   modifiedOn:   "2022-11-03T05:32:42.5992302",
          #                   createdOn:    "2022-11-03T05:27:51.4886976",
          #                   active:       true
          #                 },
          #   customer:     {
          #     id:                  72109037,
          #     name:                'Azerrad, Jacob',
          #     type:                'Residential',
          #     email:               'jacobazerrad@verizon.net',
          #     active:              true,
          #     address:             {
          #       zip:           '02420',
          #       city:          'Lexington',
          #       unit:          nil,
          #       state:         'MA',
          #       street:        '26 Drummer Boy Way',
          #       country:       'USA',
          #       latitude:      42.4786841,
          #       longitude:     -71.2481332,
          #       streetAddress: '26 Drummer Boy Way'
          #     },
          #     balance:             nil,
          #     contacts:            [
          #       {
          #         id:         72109039,
          #         memo:       nil,
          #         type:       'MobilePhone',
          #         value:      '7817896594',
          #         active:     true,
          #         modifiedOn: '2024-05-07T23:57:58.7982814'
          #       },
          #       {
          #         id:         72109040,
          #         memo:       nil,
          #         type:       'Email',
          #         value:      'jacobazerrad@verizon.net',
          #         active:     true,
          #         modifiedOn: '2024-05-07T23:57:58.8202042'
          #       }
          #     ],
          #     createdBy:           62448615,
          #     createdOn:           '2024-05-07T23:57:58.7458878',
          #     doNotMail:           false,
          #     modifiedOn:          '2024-05-10T18:46:01.7958572',
          #     memberships:         [],
          #     customFields:        [],
          #     doNotService:        false,
          #     phoneSettings:       [
          #       {
          #         doNotText:   false,
          #         phoneNumber: '7817896594'
          #       }
          #     ],
          #     hasActiveMembership: false
          #   },
          #   duration:     '00:01:13.0096991',
          #   client_id:    1234,
          #   createdBy:    {
          #     id:   50826299,
          #     name: 'Hollie Senhaji'
          #   },
          #   direction:    ['Inbound', 'Outbound'],
          #   webhookId:    60805346,
          #   controller:   'integrations/servicetitan/integrations',
          #   modifiedOn:   '2024-05-16T17:47:36.8452562',
          #   receivedOn:   '2024-05-16T17:46:23.8318303',
          #   __eventInfo:  {
          #     eventId:     '2024-05-16T17:47:37.0523962Z',
          #     webhookId:   60805346,
          #     webhookType: 'CallCompleted'
          #   },
          #   __tenantInfo: {
          #     id:   866848184,
          #     name: 'greenenergymechanical'
          #   },
          #   recordingUrl: nil,
          #   voiceMailUrl: nil
          # }

          # example args received with no customer (customer not in ST yet)
          # {
          #   id:           864308197,
          #   receivedOn:   '2024-05-16T22:42:07.459',
          #   duration:     '00:02:19.8750000',
          #   from:         '4074367689',
          #   to:           '6028371855',
          #   direction:    ['Inbound', 'Outbound'],
          #   callType:     [nil, 'Abandoned', 'Booked', 'Excused', 'NotLead', 'Unbooked'],
          #   reason:       nil,
          #   recordingUrl: 'https://go.servicetitan.com/Call/CallRecording/864308197',
          #   voiceMailUrl: nil,
          #   createdBy:    nil,
          #   customer:     nil,
          #   campaign:     nil,
          #   modifiedOn:   '2024-05-16T22:44:29.4426418',
          #   agent:        {
          #     externalId: nil,
          #     id:         260413804,
          #     name:       'Nicole Chiarolla I.C.'
          #   },
          #   eventId:      '2024-05-16T22:44:29.8529061Z',
          #   webhookId:    621980528,
          #   __eventInfo:  {
          #     eventId:     '2024-05-16T22:44:29.8529061Z',
          #     webhookId:   621980528,
          #     webhookType: 'CallCompleted'
          #   },
          #   __tenantInfo: { id: 349984906, name: 'a1garage' }
          # }
        end
      end
    end
  end
end
