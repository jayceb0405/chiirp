# frozen_string_literal: true

# app/lib/integrations/service_titan/crm_bookings.rb
module Integrations
  module ServiceTitan
    module CrmBookings
      # get a Booking from ServiceTitan APIs
      # st_client.booking()
      # (req) booking_id: (Integer)
      def booking(booking_id)
        reset_attributes
        @result = {}

        if booking_id.to_i.zero?
          @message = 'ServiceTitan Booking id is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::CrmBookings.booking',
          method:                'get',
          params:                {},
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/bookings/#{booking_id}"
        )

        # ServiceTitan seems to return the most recent Booking if no matching booking_id is found
        if @result.is_a?(Hash) && (@result.dig(:id).to_i == booking_id.to_i)
          @result = @result[:id].to_i
        else
          @result  = nil
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end

      # get Bookings from ServiceTitan
      # st_client.bookings
      # (opt) count_only:      (Boolean)
      # (opt) created_after:   (Time)
      # (opt) created_before:  (Time)
      # (opt) modified_after:  (Time)
      # (opt) modified_before: (Time)
      # (opt) page:            (Integer)
      # (opt) page_size:       (Integer)
      def bookings(args = {})
        reset_attributes
        page     = [args.dig(:page).to_i, 1].max - 1
        @result  = []
        response = @result

        params = {
          includeTotal: args.dig(:count_only).to_bool,
          pageSize:     (args.dig(:page_size) || (args.dig(:count_only).to_bool ? 1 : @page_size)).to_i
        }
        params[:createdBefore]     = args[:created_before].rfc3339 if args.dig(:created_before).respond_to?(:rfc3339)
        params[:createdOnOrAfter]  = args[:created_after].rfc3339 if args.dig(:created_after).respond_to?(:rfc3339)
        params[:modifiedBefore]    = args[:created_before].rfc3339 if args.dig(:modified_before).respond_to?(:rfc3339)
        params[:modifiedOnOrAfter] = args[:created_after].rfc3339 if args.dig(:modified_after).respond_to?(:rfc3339)

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  {},
            error_message_prepend: 'Integrations::ServiceTitan::CrmBookings.bookings',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/bookings"
          )

          if @result.is_a?(Hash)

            if args.dig(:count_only).to_bool
              response = @result.dig(:totalCount).to_i
              break
            else
              response += @result.dig(:data) || []
              break if args.dig(:page).to_i.positive?
              break unless @result.dig(:hasMore).to_bool
            end
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API for a count of bookings
      # st_client.bookings_count
      # (opt) created_after:   (Time)
      # (opt) created_before:  (Time)
      # (opt) modified_after:  (Time)
      # (opt) modified_before: (Time)
      def bookings_count(args = {})
        reset_attributes
        @result = self.bookings(args.merge(count_only: true))
      end

      # call ServiceTitan to add a new Booking
      # st_client.new_booking()
      # (req) booking_provider_id:           (Integer)
      # (req) fullname:                      (String)
      # (req) new_client:                    (Boolean)
      # (req) source:                        (String)
      # (req) summary:                       (String)
      #
      # (opt) address_01:                    (String)
      # (opt) address_02:                    (String)
      # (opt) city:                          (String)
      # (opt) country:                       (String)
      # (opt) customer_type:                 (String)
      # (opt) email:                         (String)
      # (opt) phone_numbers:                 (Array)   [[label (String), number (String)]]
      # (opt) postal_code:                   (String)
      # (opt) servicetitan_business_unit_id: (Integer)
      # (opt) servicetitan_campaign_id:      (Integer)
      # (opt) servicetitan_job_type_id:      (Integer)
      # (opt) servicetitan_priority:         (String)
      # (opt) state:                         (String)
      # (opt) unit:                          (String)
      def new_booking(args = {})
        reset_attributes
        @result = {}

        if args.dig(:booking_provider_id).to_i.zero?
          @message = 'ServiceTitan Booking Provider id is required.'
          JsonLog.info 'Integrations::ServiceTitan::CrmBookings.new_booking', { args: }
          return @result
        elsif args.dig(:fullname).to_s.empty?
          @message = 'Contact name is required.'
          JsonLog.info 'Integrations::ServiceTitan::CrmBookings.new_booking', { args: }
          return @result
        elsif args.dig(:new_client).nil?
          @message = 'New Contact designation is required.'
          JsonLog.info 'Integrations::ServiceTitan::CrmBookings.new_booking', { args: }
          return @result
        elsif args.dig(:source).to_s.empty?
          @message = 'Booking source is required.'
          JsonLog.info 'Integrations::ServiceTitan::CrmBookings.new_booking', { args: }
          return @result
        elsif args.dig(:summary).to_s.empty?
          @message = 'Booking summary is required.'
          JsonLog.info 'Integrations::ServiceTitan::CrmBookings.new_booking', { args: }
          return @result
        end

        body = {
          externalId:        SecureRandom.uuid,
          isFirstTimeClient: args.dig(:new_client).to_bool,
          name:              args.dig(:fullname).to_s,
          source:            args.dig(:source).to_s,
          summary:           args.dig(:summary).to_s
        }
        body[:address] = {
          city:    args.dig(:city).to_s,
          country: args.dig(:country).to_s.presence || (args.dig(:postal_code).to_s == args.dig(:postal_code).to_i.to_s ? 'USA' : 'CA'),
          state:   args.dig(:state).to_s,
          street:  [args.dig(:address_01).to_s, args.dig(:address_02)].compact_blank.join(', '),
          unit:    args.dig(:unit).to_s,
          zip:     args.dig(:postal_code).to_s
        }
        body[:contacts]  = []
        body[:contacts] << { type: 'Email', value: args[:email].to_s } if args.dig(:email).to_s.present?

        args.dig(:phone_numbers).each do |label, number|
          body[:contacts] << { type: self.normalize_phone_label(label), value: number }
        end

        body[:customerType]            = args[:customer_type].to_s if args.dig(:customer_type).to_s.present?
        body[:campaignId]              = args[:servicetitan_campaign_id].to_i if args.dig(:servicetitan_campaign_id).to_i.positive?
        body[:businessUnitId]          = args[:servicetitan_business_unit_id].to_i if args.dig(:servicetitan_business_unit_id).to_i.positive?
        body[:jobTypeId]               = args[:servicetitan_job_type_id].to_i if args.dig(:servicetitan_job_type_id).to_i.positive?
        body[:priority]                = args[:servicetitan_priority].to_s if args.dig(:servicetitan_priority).to_s.present?
        body[:isSendConfirmationEmail] = false

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::CrmBookings.new_booking',
          method:                'post',
          params:                {},
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/booking-provider/#{args[:booking_provider_id].to_i}/bookings"
        )
      end

      # get Bookings from ServiceTitan by provider
      # st_client.provider_bookings
      # (req) booking_provider_id: (Integer)
      # (opt) count_only:          (Boolean)
      # (opt) created_after:       (Time)
      # (opt) created_before:      (Time)
      # (opt) modified_after:      (Time)
      # (opt) modified_before:     (Time)
      # (opt) page:                (Integer)
      # (opt) page_size:           (Integer)
      def provider_bookings(args = {})
        reset_attributes
        @result = []

        if args.dig(:booking_provider_id).to_i.zero?
          @message = 'ServiceTitan Booking Provider id is required.'
          return @result
        end

        page     = [args.dig(:page).to_i, 1].max - 1
        response = @result
        params   = {
          includeTotal: args.dig(:count_only).to_bool,
          pageSize:     (args.dig(:page_size) || (args.dig(:count_only).to_bool ? 1 : @page_size)).to_i
        }
        params[:createdBefore]     = args[:created_before].rfc3339 if args.dig(:created_before).respond_to?(:rfc3339)
        params[:createdOnOrAfter]  = args[:created_after].rfc3339 if args.dig(:created_after).respond_to?(:rfc3339)
        params[:modifiedBefore]    = args[:created_before].rfc3339 if args.dig(:modified_before).respond_to?(:rfc3339)
        params[:modifiedOnOrAfter] = args[:created_after].rfc3339 if args.dig(:modified_after).respond_to?(:rfc3339)

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  {},
            error_message_prepend: 'Integrations::ServiceTitan::CrmBookings.provider_bookings',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/booking-provider/#{args[:booking_provider_id].to_i}/bookings"
          )

          if @result.is_a?(Hash)

            if args.dig(:count_only).to_bool
              response = @result.dig(:totalCount).to_i
              break
            else
              response += @result.dig(:data) || []
              break if args.dig(:page).to_i.positive?
              break unless @result.dig(:hasMore).to_bool
            end
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API for a count of bookings by provider
      # st_client.provider_bookings_count
      # (req) booking_provider_id: (Integer)
      # (opt) created_after:   (Time)
      # (opt) created_before:  (Time)
      # (opt) modified_after:  (Time)
      # (opt) modified_before: (Time)
      def provider_bookings_count(args = {})
        reset_attributes
        @result = self.provider_bookings(args.merge(count_only: true))
      end
    end
  end
end
