# frozen_string_literal: true

# app/lib/integrations/service_titan/telecom.rb
module Integrations
  module ServiceTitan
    module Telecom
      # call ServiceTitan API for a call
      # st_client.call(st_call_id: Integer)
      #   (req) st_call_id: (Integer)
      def call(args = {})
        reset_attributes
        @result = {}

        if args.dig(:st_call_id).to_i.zero?
          @message = 'ServiceTitan Call ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::Telecom.call',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_telecom}/#{api_version}/tenant/#{self.tenant_id}/calls/#{args[:st_call_id].to_i}"
        )
      end
      # example response
      # {
      #   leadCall:     { id:           72336470,
      #                   receivedOn:   '2024-05-16T16:19:20.1641653Z',
      #                   duration:     '00:01:15',
      #                   from:         '+17817677940',
      #                   to:           '7817849416',
      #                   direction:    'Outbound',
      #                   callType:     nil,
      #                   reason:       nil,
      #                   recordingUrl: 'https://go.servicetitan.com/Call/CallRecording/72336470',
      #                   voiceMailUrl: nil,
      #                   createdBy:    { id: 50826299, name: 'Hollie Senhaji' },
      #                   customer:     { id:                  37086407,
      #                                   active:              true,
      #                                   name:                'Rubenstein, Gregg',
      #                                   email:               'gar2@comcast.net',
      #                                   balance:             nil,
      #                                   doNotMail:           false,
      #                                   address:             { street: '30 Magnolia Road', unit: nil, country: 'USA', city: 'Sharon', state: 'MA', zip: '02067', streetAddress: '30 Magnolia Road', latitude: 42.1041553, longitude: -71.1497022 },
      #                                   doNotService:        false,
      #                                   type:                'Residential',
      #                                   contacts:            [{ active: true, modifiedOn: '2023-01-25T16:55:02.1536082Z', id: 37086409, type: 'Email', value: 'gar2@comcast.net', memo: nil },
      #                                                         { active: true, modifiedOn: '2021-10-22T16:39:09.42299Z', id: 37086410, type: 'Phone', value: '7817849416', memo: 'Home phone' }],
      #                                   modifiedOn:          '2024-05-16T16:23:01.8796512Z',
      #                                   memberships:         [{ id:         39113796,
      #                                                           active:     true,
      #                                                           type:       { id: 17577805, active: true, name: 'Furnace Peace of Mind Plan' },
      #                                                           status:     'Expired',
      #                                                           from:       '2021-11-10T00:00:00Z',
      #                                                           to:         '2022-11-09T00:00:00Z',
      #                                                           locationId: 37086411 },
      #                                                         { id:         51665862,
      #                                                           active:     false,
      #                                                           type:       { id: 17574606, active: true, name: 'Add On GEM Central AC Membership' },
      #                                                           status:     'Deleted',
      #                                                           from:       '2022-11-02T00:00:00Z',
      #                                                           to:         '2023-11-01T00:00:00Z',
      #                                                           locationId: 37086411 },
      #                                                         { id:         51667263,
      #                                                           active:     true,
      #                                                           type:       { id: 17574606, active: true, name: 'Add On GEM Central AC Membership' },
      #                                                           status:     'Active',
      #                                                           from:       '2022-11-21T00:00:00Z',
      #                                                           to:         '2026-11-20T00:00:00Z',
      #                                                           locationId: 37086411 },
      #                                                         { id:         51669565,
      #                                                           active:     true,
      #                                                           type:       { id: 17577805, active: true, name: 'Furnace Peace of Mind Plan' },
      #                                                           status:     'Active',
      #                                                           from:       '2022-11-21T00:00:00Z',
      #                                                           to:         '2026-11-20T00:00:00Z',
      #                                                           locationId: 37086411 }],
      #                                   hasActiveMembership: true,
      #                                   customFields:        [],
      #                                   createdOn:           '2021-10-22T16:39:09.3457506Z',
      #                                   createdBy:           17590733,
      #                                   phoneSettings:       [{ phoneNumber: '7817849416', doNotText: false }] },
      #                   campaign:     nil,
      #                   modifiedOn:   '2024-05-16T16:20:39.0927155Z',
      #                   agent:        { externalId: nil, id: 50826299, name: 'Hollie Senhaji' } },
      #   id:           0,
      #   jobNumber:    nil,
      #   projectId:    0,
      #   businessUnit: nil,
      #   type:         nil
      # }

      # call ServiceTitan API for calls
      # st_client.calls
      #   (opt) active_only:         (Boolean)
      #   (opt) phone_number_called: (String)
      #   (opt) created_after:       (Time)
      def calls(args = {})
        reset_attributes
        @result  = []
        page     = 0
        response = @result
        params   = {
          activeOnly:   args.dig(:active_only).nil? ? true : args[:active_only].to_bool,
          createdAfter: (args.dig(:created_after).respond_to?(:iso8601) ? args.dig(:created_after) : 1.day.ago).iso8601,
          pageSize:     @page_size
        }
        params[:phoneNumberCalled] = args[:phone_number_called].to_s if args.dig(:phone_number_called).present?

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Telecom.calls',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_telecom}/#{api_version}/tenant/#{self.tenant_id}/calls"
          )

          if @result.is_a?(Hash)

            @result&.dig(:data)&.each do |call|
              if call.dig(:leadCall)
                response << {
                  id:          call.dig(:leadCall, :id).to_i,
                  receivedOn:  call.dig(:leadCall, :receivedOn).to_s,
                  from:        call.dig(:leadCall, :from).to_s,
                  to:          call.dig(:leadCall, :to).to_s,
                  direction:   call.dig(:leadCall, :direction).to_s,
                  callType:    call.dig(:leadCall, :callType).to_s,
                  reason:      call.dig(:leadCall, :reason, :name).to_s,
                  customer_id: call.dig(:leadCall, :customer, :id).to_i,
                  campaign:    call.dig(:leadCall, :campaign, :name).to_s
                }
              end
            end

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

      # update ServiceTitan Call.callType
      # st_client.update_call_type()
      #   (req) call_id:   (Integer)
      #   (opt) call_type: (String)
      #   (opt) excuse:    (String)
      #   (opt) reason:    (Hash) ex: { name: (String), lead: (Boolean) }
      def update_call_type(args = {})
        reset_attributes
        @result = 0

        if args.dig(:call_id).to_i.zero?
          @message = 'ServiceTitan Call ID is required.'
          return @result
        end

        push_attributes('telecom_update_call_type')

        if (st_call = self.call(call_id: args[:call_id]))
          st_customer = {
            id:      st_call.dig(:leadCall, :customer, :id).to_i,
            name:    st_call.dig(:leadCall, :customer, :name).to_s,
            address: st_call.dig(:leadCall, :customer, :address) || {}
          }
        else
          @message = "Unable to locate ServiceTitan call by ID: #{args[:call_id].to_i}"
          return @result
        end

        if (st_locations = self.locations(customer_id: st_customer.dig(:id).to_i))
          st_location = {
            id:      st_locations.first&.dig(:id).to_i,
            name:    st_locations.first&.dig(:name).to_s,
            address: st_locations.first&.dig(:address) || {}
          }
        else
          @message = "Unable to locate ServiceTitan customer by ID: #{st_customer.dig(:id).to_i}"
          return @result
        end

        pull_attributes('telecom_update_call_type')

        body = {
          callType:   (args.dig(:call_type) || 'Booked').to_s.strip,
          excuseMemo: args.dig(:excuse).to_s,
          reason:     args.dig(:reason) || { name: 'New Order', lead: true },
          customer:   st_customer,
          location:   st_location
        }

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::Telecom.update_call_type',
          method:                'put',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_telecom}/#{api_version}/tenant/#{self.tenant_id}/calls/#{args[:call_id].to_i}"
        )

        if @result.is_a?(Hash)
          @result = @result&.dig(:id).to_i
        else
          @result  = 0
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end
    end
  end
end
