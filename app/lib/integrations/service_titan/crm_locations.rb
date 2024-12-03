# frozen_string_literal: true

# app/lib/integrations/service_titan/crm_locations.rb
module Integrations
  module ServiceTitan
    module CrmLocations
      # add ServiceTitan Location for a specific Contact
      # st_client.add_location(
      #   customer_id:   Integer,
      #   firstname:     String,
      #   lastname:      String,
      #   address_01:    String,
      #   address_02:    String,
      #   city:          String,
      #   state:         String,
      #   postal_code:   String,
      #   email:         String,
      #   phone_numbers: Array
      # )
      def add_location(args = {})
        reset_attributes
        @result = ''

        if args.dig(:customer_id).to_i.zero?
          @message = 'ServiceTitan Customer ID is required.'
          return @result
        end

        contacts = []
        contacts << { type: 'Email', value: args.dig(:email).to_s } if args.dig(:email).to_s.present?

        (args.dig(:phone_numbers) || []).each do |phone_number|
          contacts << { type: self.normalize_phone_label(phone_number[0]), value: phone_number[1] }
        end

        body = {
          name:       [args.dig(:firstname).to_s, args.dig(:lastname).to_s].join(' '),
          customerId: args.dig(:customer_id).to_i,
          address:    {
            street:  [args.dig(:address_01).to_s, args.dig(:address_02)].compact_blank.join(', '),
            city:    args.dig(:city).to_s,
            state:   args.dig(:state).to_s,
            zip:     args.dig(:postal_code).to_s,
            country: 'USA'
          },
          contacts:
        }

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::CrmLocations.add_location',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/locations"
        )

        if @result.is_a?(Hash)
          @result = @result&.dig(:contacts)&.first&.dig(:id).to_s
        else
          @result  = ''
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end

      # call ServiceTitan API for a location
      # st_client.location()
      # (req) location_id: (Integer)
      def location(location_id)
        reset_attributes
        @result = {}

        if location_id.to_i.zero?
          @message = 'ServiceTitan Location id is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceTitan::CrmLocations.location',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/locations/#{location_id.to_i}"
        )
      end

      # call ServiceTitan API for customer locations
      # st_client.locations()
      #   (req) customer_id:     (Integer)
      #   (opt) active_only:     (Boolean)
      #   (opt) st_location_ids: (Array of Integers / max 50)
      def locations(args = {})
        reset_attributes
        @result = []

        return @result if args.dig(:customer_id).to_i.zero? && args.dig(:st_location_ids).blank?

        page     = 0
        response = @result
        params   = {
          active:   args.dig(:active_only).nil? ? true : args[:active_only].to_bool,
          pageSize: @page_size
        }
        params[:customerId] = args[:customer_id].to_i if args.dig(:customer_id).to_i.positive?
        params[:ids]        = args[:st_location_ids].map(&:to_s).join(',') if args.dig(:st_location_ids).is_a?(Array) && args[:st_location_ids].present?

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::CrmLocations.locations',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/locations"
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
    end
  end
end
