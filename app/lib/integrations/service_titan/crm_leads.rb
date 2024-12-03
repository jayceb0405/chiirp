# frozen_string_literal: true

# app/lib/integrations/service_titan/crm_leads.rb
module Integrations
  module ServiceTitan
    module CrmLeads
      # get a Lead from ServiceTitan
      # st_client.leads
      def leads
        reset_attributes
        @result = []

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.leads',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/leads"
        )
      end

      # Create a new ServiceTitan Lead for a specific Contact
      # st_client.new_lead(
      #   firstname:     String,
      #   lastname:      String,
      #   address_01:    String,
      #   address_02:    String,
      #   city:          String,
      #   state:         String,
      #   postal_code:   String,
      #   email:         String,
      #   ok2email:      Boolean,
      #   phone_numbers: Array,
      #   custom_fields: Hash
      # )
      def new_lead(args = {})
        reset_attributes
        custom_fields = []

        (args.dig(:custom_fields)&.deep_symbolize_keys || {}).each do |st_custom_field_id, values|
          custom_fields << {
            typeId: st_custom_field_id.to_i,
            name:   values[:name].to_s,
            value:  values[:value].to_s
          }
        end

        contacts = []
        contacts << { type: 'Email', value: args.dig(:email).to_s, memo: 'test' } if args.dig(:email).to_s.present?

        (args.dig(:phone_numbers) || []).each do |phone_number|
          contacts << { type: self.normalize_phone_label(phone_number[0]), value: phone_number[1], memo: 'test' }
        end

        body = {
          name:         [args.dig(:firstname).to_s, args.dig(:lastname).to_s].compact_blank.join(' '),
          doNotMail:    if args.dig(:ok2email).nil?
                          false
                        else
                          (args.dig(:ok2email).to_bool ? false : true)
                        end,
          doNotService: false,
          locations:    [
            {
              name:     [args.dig(:firstname).to_s, args.dig(:lastname).to_s].compact_blank.join(' '),
              address:  {
                street:  [args.dig(:address_01).to_s, args.dig(:address_02)].compact_blank.join(', '),
                city:    args.dig(:city).to_s,
                state:   args.dig(:state).to_s,
                zip:     args.dig(:postal_code).to_s,
                country: 'USA'
              },
              contacts:
            }
          ],
          address:      {
            street:  [args.dig(:address_01).to_s, args.dig(:address_02)].compact_blank.join(', '),
            city:    args.dig(:city).to_s,
            state:   args.dig(:state).to_s,
            zip:     args.dig(:postal_code).to_s,
            country: 'USA'
          },
          contacts:,
          customFields: custom_fields
        }

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.new_lead',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers"
        )

        if @result.is_a?(Hash)
          @result = { customer_id: @result&.dig(:id).to_i, location_id: 0 }

          if @result[:customer_id].positive?
            self.push_attributes('new_customer')
            locations = self.locations(customer_id: @result[:customer_id])
            self.pull_attributes('new_customer')

            @result[:location_id] = locations.first.dig(:id).to_i if locations.present?
          end

          @success = true
        else
          @result  = { customer_id: 0, location_id: 0 }
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end
    end
  end
end
