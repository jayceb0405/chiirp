# frozen_string_literal: true

# app/lib/integrations/service_titan/crm_customers.rb
module Integrations
  module ServiceTitan
    module CrmCustomers
      # call ServiceTitan API for a customer
      # st_client.customer()
      # (req) customer_id: (Integer)
      def customer(customer_id)
        reset_attributes
        @result = {}

        if customer_id.to_i.zero?
          @message = 'ServiceTitan Customer id is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.customer',
          method:                'get',
          params:                {},
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers/#{customer_id.to_i}"
        )

        if success?
          self.push_attributes('customer')
          @result[:contacts] = self.customer_contacts(customer_id)
          self.pull_attributes('customer')
        else
          @result[:contacts] = []
        end

        @result
      end
      # example ServiceTitan customer model
      # {
      #   :id=>204421041,
      #   :active=>true,
      #   :name=>"Ashly Escobar ",
      #   :type=>"Residential",
      #   :address=>{
      #     :street=>"1038 Vanston Way",
      #     :unit=>nil,
      #     :city=>"Roseville",
      #     :state=>"CA",
      #     :zip=>"95747",
      #     :country=>"USA",
      #     :latitude=>38.75369209999999,
      #     :longitude=>-121.3374854
      #   },
      #   :customFields=>[],
      #   :balance=>0.0,
      #   :tagTypeIds=>[],
      #   :doNotMail=>false,
      #   :doNotService=>false,
      #   :createdOn=>"2023-03-12T23:12:27.753398Z",
      #   :createdById=>152441865,
      #   :modifiedOn=>"2023-03-12T23:12:27.7622606Z",
      #   :mergedToId=>nil,
      #   :externalData=>nil
      # }

      # call ServiceTitan API for a customer's contacts
      # st_client.customer_contacts()
      # (req) st_customer_id: (Integer)
      def customer_contacts(st_customer_id)
        reset_attributes
        @result = []

        if st_customer_id.to_i.zero?
          @message = 'ServiceTitan Customer ID is required.'
          return @result
        end

        page     = 0
        response = @result
        params   = { pageSize: @page_size }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.customer_contacts',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers/#{st_customer_id}/contacts"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API for a count of customers
      # st_client.customer_count
      #   (opt) active_only:    (Boolean)
      #   (opt) created_after:  (Time)
      #   (opt) created_before: (Time)
      def customer_count(args = {})
        reset_attributes
        @result = self.customers(args.merge(count_only: true))
      end

      # call ServiceTitan API for customers
      # st_client.customers()
      #   (opt) active:          (Boolean)
      #   (opt) city:            (String)
      #   (opt) count_only:      (Boolean)
      #   (opt) created_after:   (Time)
      #   (opt) created_before:  (Time)
      #   (opt) modified_after:  (Time)
      #   (opt) modified_before: (Time)
      #   (opt) name:            (String)
      #   (opt) page:            (Integer)
      #   (opt) page_size:       (Integer)
      #   (opt) phone:           (String)
      #   (opt) postal_code:     (String)
      #   (opt) state:           (String)
      #   (opt) street:          (String)
      #   (opt) st_customer_ids: (Array of Integers / max 50)
      #   (opt) unit:            (String)
      def customers(args = {})
        reset_attributes
        @result = []
        params  = {
          page:     [args.dig(:page).to_i, 1].max,
          pageSize: (args.dig(:page_size) || (args.dig(:count_only).to_bool ? 1 : @page_size)).to_i
        }
        params[:active]            = args.dig(:active).nil? ? 'Any' : args[:active].to_s.titleize
        params[:city]              = args[:city] if args.dig(:city).present?
        params[:createdBefore]     = args[:created_before].iso8601 if args.dig(:created_before).respond_to?(:iso8601)
        params[:createdOnOrAfter]  = args[:created_after].iso8601 if args.dig(:created_after).respond_to?(:iso8601)
        params[:ids]               = args[:st_customer_ids].map(&:to_s).join(',') if args.dig(:st_customer_ids).is_a?(Array)
        params[:includeTotal]      = args.dig(:count_only).to_bool
        params[:modifiedBefore]    = args[:created_before].iso8601 if args.dig(:modified_before).respond_to?(:iso8601)
        params[:modifiedOnOrAfter] = args[:created_after].iso8601 if args.dig(:modified_after).respond_to?(:iso8601)
        params[:name]              = args[:name] if args.dig(:name).present?
        params[:phone]             = args[:phone] if args.dig(:phone).present?
        params[:state]             = args[:state] if args.dig(:state).present?
        params[:street]            = args[:street] if args.dig(:street).present?
        params[:unit]              = args[:unit] if args.dig(:unit).present?
        params[:zip]               = args[:postal_code] if args.dig(:postal_code).present?

        self.servicetitan_request(
          body:                  {},
          error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.customers',
          method:                'get',
          params:,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers"
        )

        @result = if @result.is_a?(Hash)
                    args.dig(:count_only).to_bool ? @result.dig(:totalCount).to_i : @result.dig(:data)
                  else
                    args.dig(:count_only).to_bool ? 0 : []
                  end
      end
      # example ServiceTitan customer models
      # [
      #   {
      #     id:           204421041,
      #     active:       true,
      #     name:         'Ashly Escobar ',
      #     type:         'Residential',             (Residential, Commercial)
      #     address:      {
      #       street:    '1038 Vanston Way',
      #       unit:      nil,
      #       city:      'Roseville',
      #       state:     'CA',
      #       zip:       '95747',
      #       country:   'USA',
      #       latitude:  38.75369209999999,
      #       longitude: -121.3374854
      #     },
      #     customFields: [],
      #     balance:      0.0,
      #     tagTypeIds:   [],
      #     doNotMail:    false,
      #     doNotService: false,
      #     createdOn:    '2023-03-12T23:12:27.753398Z',
      #     createdById:  152441865,
      #     modifiedOn:   '2023-03-12T23:12:27.7622606Z',
      #     mergedToId:   nil,
      #     externalData: nil
      #   }, ...
      # ]

      # call ServiceTitan API for multiple customer's contacts
      # st_client.customers_contacts()
      #   (req) st_customer_ids: (Array)
      #   (opt) page_size:       (Array / default: @page_size)
      def customers_contacts(st_customer_ids:, **args)
        reset_attributes
        @result = []

        if !st_customer_ids.is_a?(Array) || st_customer_ids.blank?
          @message = 'ServiceTitan Customer IDs are required.'
          return @result
        end

        response = @result
        params   = { pageSize: (args.dig(:page_size).presence || @page_size).to_i }
        st_customer_ids_block_size = st_customer_ids.length / (st_customer_ids.join(',').length / 1900.00).ceil

        (0..((st_customer_ids.length.to_f / st_customer_ids_block_size).ceil - 1)).each do |st_customer_ids_block|
          page = 0
          params[:customerIds] = st_customer_ids[(st_customer_ids_block * st_customer_ids_block_size)..((st_customer_ids_block * st_customer_ids_block_size) + st_customer_ids_block_size - 1)].map(&:to_s).join(',')

          loop do
            page += 1
            params[:page] = page

            self.servicetitan_request(
              body:                  nil,
              error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.customers_contacts',
              method:                'get',
              params:,
              default_result:        [],
              url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers/contacts"
            )

            if @result.is_a?(Hash)
              response += @result.dig(:data) || []
              break unless @result.dig(:hasMore)&.to_bool
            else
              response = []
              @success = false
              @message = "Unexpected response: #{@result.inspect}"
              break
            end
          end
        end

        @result = response
      end

      # Create a new ServiceTitan Customer for a specific Contact
      # st_client.new_customer(
      #   firstname:     String,
      #   lastname:      String,
      #   address_01:    String,
      #   address_02:    String,
      #   city:          String,
      #   state:         String,
      #   postal_code:   String,
      #   email:         String,
      #   ok2email:      Boolean,
      #   customer_type: String (Residential, Commercial),
      #   phone_numbers: Array,
      #   custom_fields: Hash
      # )
      def new_customer(args = {})
        reset_attributes
        response = { customer_id: 0, location_id: 0 }

        custom_fields = []

        (args.dig(:custom_fields)&.deep_symbolize_keys || {}).each do |st_custom_field_id, values|
          custom_fields << {
            typeId: st_custom_field_id.to_i,
            name:   values[:name].to_s,
            value:  values[:value].to_s
          }
        end

        contacts = []
        contacts << { type: 'Email', value: args.dig(:email).to_s } if args.dig(:email).to_s.present?

        (args.dig(:phone_numbers) || []).each do |phone_number|
          contacts << { type: self.normalize_phone_label(phone_number[0]), value: phone_number[1] }
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
                street:  [args.dig(:address1).to_s, args.dig(:address2)].compact_blank.join(', '),
                city:    args.dig(:city).to_s,
                state:   args.dig(:state).to_s,
                zip:     args.dig(:zipcode).to_s,
                country: 'USA'
              },
              contacts:
            }
          ],
          address:      {
            street:  [args.dig(:address1).to_s, args.dig(:address2)].compact_blank.join(', '),
            city:    args.dig(:city).to_s,
            state:   args.dig(:state).to_s,
            zip:     args.dig(:zipcode).to_s,
            country: 'USA'
          },
          contacts:,
          customFields: custom_fields
        }
        body[:type] = args[:customer_type].to_s.titleize if args.dig(:customer_type).to_s.present?

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.new_customer',
          method:                'post',
          params:                {},
          default_result:        response,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers"
        )

        if @result.is_a?(Hash) && @result.dig(:id)
          response[:customer_id] = @result[:id].to_i

          if response[:customer_id].positive?
            self.push_attributes('new_customer')
            locations = self.locations(customer_id: response[:customer_id])
            self.pull_attributes('new_customer')

            response[:location_id] = locations&.first&.dig(:id).to_i
          end
        else
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result = response
      end

      # update ServiceTitan Customer for a specific Contact
      # st_client.update_customer(
      #   customer_id:   (Integer),
      #   firstname:     (String),
      #   lastname:      (String),
      #   address1:      (String),
      #   address2:      (String),
      #   city:          (String),
      #   state:         (String),
      #   zipcode:       (String),
      #   email:         (String),
      #   ok2email:      (Boolean),
      #   phone_numbers: (Array),
      #   custom_fields: (Hash),
      #   customer_type: (String) Residential / Commercial
      # )
      def update_customer(args = {})
        reset_attributes
        @result = ''

        if args.dig(:customer_id).to_i.zero?
          @message = 'ServiceTitan Customer ID is required.'
          return @result
        end

        custom_fields = []

        (args.dig(:custom_fields)&.deep_symbolize_keys || {}).each do |st_custom_field_id, values|
          custom_fields << {
            typeId: st_custom_field_id.to_i,
            name:   values[:name].to_s,
            value:  values[:value].to_s
          }
        end

        contacts = []
        contacts << { type: 'Email', value: args.dig(:email).to_s } if args.dig(:email).to_s.present?

        (args.dig(:phone_numbers) || []).each do |phone_number|
          contacts << { type: self.normalize_phone_label(phone_number[0]), value: phone_number[1] }
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
                street:  [args.dig(:address1).to_s, args.dig(:address2)].compact_blank.join(', '),
                city:    args.dig(:city).to_s,
                state:   args.dig(:state).to_s,
                zip:     args.dig(:zipcode).to_s,
                country: 'USA'
              },
              contacts:
            }
          ],
          address:      {
            street:  [args.dig(:address1).to_s, args.dig(:address2)].compact_blank.join(', '),
            city:    args.dig(:city).to_s,
            state:   args.dig(:state).to_s,
            zip:     args.dig(:zipcode).to_s,
            country: 'USA'
          },
          contacts:,
          customFields: custom_fields,
          active:       true
        }
        body[:type] = args[:customer_type].to_s if args.dig(:customer_type).to_s.present?

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::CrmCustomers.update_customer',
          method:                'patch',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers/#{args[:customer_id].to_i}"
        )

        @result = @result.is_a?(Hash) ? @result&.dig(:id).to_s : ''
      end
    end
  end
end
