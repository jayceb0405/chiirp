# frozen_string_literal: true

# app/models/integration/servicetitan/v2/calls.rb
module Integration
  module Servicetitan
    module V2
      module Calls
        module Base
          include Servicetitan::V2::Calls::CallReasons

          CALL_DIRECTIONS = %w[Inbound Outbound].freeze
          CALL_TYPES      = %w[Abandoned Booked Excused NotLead Unbooked].freeze

          # return a call from ServiceTitan
          # st_model.call()
          #   (req) st_call_id: (Integer)
          def call(**args)
            reset_attributes
            @result = {}

            if args.dig(:st_call_id).blank?
              @message = 'ServiceTitan call ID is required.'
              return @result
            end

            @st_client.call(st_call_id: args[:st_call_id])

            update_attributes_from_client

            @result = @result.dig(:leadCall) || {} if @success

            @result
          end
          # example result
          # {
          #   id:           72336470,
          #   receivedOn:   '2024-05-16T16:19:20.1641653Z',
          #   duration:     '00:01:15',
          #   from:         '+17817677940',
          #   to:           '7817849416',
          #   direction:    'Outbound',
          #   callType:     nil,
          #   reason:       nil,
          #   recordingUrl: 'https://go.servicetitan.com/Call/CallRecording/72336470',
          #   voiceMailUrl: nil,
          #   createdBy:    { id: 50826299, name: 'Hollie Senhaji' },
          #   customer:     { id:                  37086407,
          #                   active:              true,
          #                   name:                'Rubenstein, Gregg',
          #                   email:               'gar2@comcast.net',
          #                   balance:             nil,
          #                   doNotMail:           false,
          #                   address:             { street: '30 Magnolia Road', unit: nil, country: 'USA', city: 'Sharon', state: 'MA', zip: '02067', streetAddress: '30 Magnolia Road', latitude: 42.1041553, longitude: -71.1497022 },
          #                   doNotService:        false,
          #                   type:                'Residential',
          #                   contacts:            [{ active: true, modifiedOn: '2023-01-25T16:55:02.1536082Z', id: 37086409, type: 'Email', value: 'gar2@comcast.net', memo: nil },
          #                                         { active: true, modifiedOn: '2021-10-22T16:39:09.42299Z', id: 37086410, type: 'Phone', value: '7817849416', memo: 'Home phone' }],
          #                   modifiedOn:          '2024-05-16T16:23:01.8796512Z',
          #                   memberships:         [{ id:         39113796,
          #                                           active:     true,
          #                                           type:       { id: 17577805, active: true, name: 'Furnace Peace of Mind Plan' },
          #                                           status:     'Expired',
          #                                           from:       '2021-11-10T00:00:00Z',
          #                                           to:         '2022-11-09T00:00:00Z',
          #                                           locationId: 37086411 },
          #                                         { id:         51665862,
          #                                           active:     false,
          #                                           type:       { id: 17574606, active: true, name: 'Add On GEM Central AC Membership' },
          #                                           status:     'Deleted',
          #                                           from:       '2022-11-02T00:00:00Z',
          #                                           to:         '2023-11-01T00:00:00Z',
          #                                           locationId: 37086411 },
          #                                         { id:         51667263,
          #                                           active:     true,
          #                                           type:       { id: 17574606, active: true, name: 'Add On GEM Central AC Membership' },
          #                                           status:     'Active',
          #                                           from:       '2022-11-21T00:00:00Z',
          #                                           to:         '2026-11-20T00:00:00Z',
          #                                           locationId: 37086411 },
          #                                         { id:         51669565,
          #                                           active:     true,
          #                                           type:       { id: 17577805, active: true, name: 'Furnace Peace of Mind Plan' },
          #                                           status:     'Active',
          #                                           from:       '2022-11-21T00:00:00Z',
          #                                           to:         '2026-11-20T00:00:00Z',
          #                                           locationId: 37086411 }],
          #                   hasActiveMembership: true,
          #                   customFields:        [],
          #                   createdOn:           '2021-10-22T16:39:09.3457506Z',
          #                   createdBy:           17590733,
          #                   phoneSettings:       [{ phoneNumber: '7817849416', doNotText: false }] },
          #   campaign:     nil,
          #   modifiedOn:   '2024-05-16T16:20:39.0927155Z',
          #   agent:        { externalId: nil, id: 50826299, name: 'Hollie Senhaji' }
          # }

          # update the call data for a ServiceTitan customer
          # st_model.update_call_type()
          #   (req) booked_at:    (DateTime)
          #   (req) contact_id:   (Integer)
          #   (opt) call_type:    (String)
          #   (opt) phone_number: (String)
          def update_call_type(args = {})
            JsonLog.info 'Integration::Servicetitan::V2::Calls::Base.update_call_type', { args: }
            return unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id])) && args.dig(:booked_at).respond_to?(:strftime) &&
                          self.valid_credentials?

            phone_numbers = ([args.dig(:phone_number).to_s.clean_phone(contact.client.primary_area_code)] + contact.phone_numbers(50)).compact_blank
            calls_result  = @st_client.calls(active_only: true, created_after: args[:booked_at] - 10.minutes)

            return if calls_result.blank?

            calls_result.select { |call| phone_numbers.include?(call[:from].clean_phone(contact.client.primary_area_code)) }.each do |call|
              @st_client.update_call_type(call_id: call.dig(:id), call_type: (args.dig(:call_type) || 'Booked').to_s, reason: { name: 'Five9', lead: true })
            end
          end
        end
      end
    end
  end
end
