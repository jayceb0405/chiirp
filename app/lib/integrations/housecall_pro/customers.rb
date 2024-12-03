# frozen_string_literal: true

# app/lib/integrations/housecall_pro/customers.rb
module Integrations
  module HousecallPro
    module Customers
      # get a Housecall Pro customer
      # hcp_client.customer(customer_id)
      def customer(customer_id)
        reset_attributes
        @result = []

        if customer_id.to_s.blank?
          @error_message = 'Housecall Pro Customer ID is required.'
          return @result
        end

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Customers.customer',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/customers/#{customer_id}"
        )

        @result
      end

      # get Housecall Pro customer address
      # hcp_client.customer_address(customer_id: String, address_id: String)
      def customer_address(args = {})
        reset_attributes
        address_id  = args.dig(:address_id).to_s
        customer_id = args.dig(:customer_id).to_s
        @result     = {}

        if address_id.empty? || customer_id.empty?
          @message = 'Housecall Pro customer ID & address ID is required.'
          return @result
        end

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Customers.customer_address',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/customers/#{customer_id}/addresses/#{address_id}"
        )

        @result = {
          address1: @result.dig('street').to_s,
          address2: @result.dig('street_line_2').to_s,
          city:     @result.dig('city').to_s,
          state:    @result.dig('state').to_s,
          zipcode:  @result.dig('zip').to_s
        }
      end

      # get Housecall Pro customers
      # hcp_client.customers(page: Integer, page_size: Integer)
      def customers(**args)
        reset_attributes
        page      = (args.dig(:page) || 1).to_i
        page_size = [(args.dig(:page_size) || 200).to_i, 200].min
        @result   = []

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Customers.customers',
          method:                'get',
          params:                { page:, page_size: },
          default_result:        @result,
          url:                   "#{base_url}/customers"
        )

        @result = @result.is_a?(Hash) ? @result.dig(:customers) || [] : []
      end

      # get count of all Housecall Pro customers
      # hcp_client.customers_count
      def customers_count
        reset_attributes
        @result = 0

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Customers.customers_count',
          method:                'get',
          params:                { page: 1, page_size: 1 },
          default_result:        @result,
          url:                   "#{base_url}/customers"
        )

        @result = (@result.is_a?(Hash) ? @result.dig(:total_items) : 0).to_i
      end

      # push Contact into Housecall Pro customer data
      # hcp_client.push_contact_to_housecallpro()
      #   (req) contact: (Hash)
      def push_contact_to_housecallpro(contact = {})
        reset_attributes
        @result = ''

        if !contact.is_a?(Hash) || contact.blank?
          @message = 'Contact data is required.'
          return @result
        elsif (contact.dig(:lastname).to_s + contact.dig(:firstname).to_s + contact.dig(:companyname).to_s + contact.dig(:email).to_s).blank?
          @message = 'Name, Company Name or Email is required.'
          return @result
        end

        body = {
          first_name:            contact.dig(:firstname).to_s[...190], # Housecall Pro maximum characters = 191
          last_name:             contact.dig(:lastname).to_s[...190],
          company:               contact.dig(:companyname).to_s[...190],
          email:                 contact.dig(:email).to_s,
          notifications_enabled: true,
          mobile_number:         contact.dig(:phone).to_s.slice(0..9).ljust(10, '0'), # Housecall Pro will return an error if the phone number is NOT exactly 10 digits
          tags:                  contact.dig(:tags), # format as array ['asdf', 'qwerty']
          addresses:             [
            {
              street:        contact.dig(:address1).to_s,
              street_line_2: contact.dig(:address2).to_s,
              city:          contact.dig(:city).to_s,
              state:         contact.dig(:state).to_s,
              zip:           contact.dig(:zipcode).to_s
            }
          ]
        }

        self.housecallpro_request(
          body:,
          error_message_prepend: 'Integrations::HousecallPro::Customers.push_contact_to_housecallpro',
          method:                contact.dig(:ext_ref_id).present? ? 'put' : 'post',
          params:                nil,
          default_result:        @result,
          url:                   contact.dig(:ext_ref_id).present? ? "#{base_url}/customers/#{contact[:ext_ref_id]}" : "#{base_url}/customers"
        )

        @result = (@result.is_a?(Hash) ? @result.dig(:id) : '').to_s
      end
    end
  end
end
