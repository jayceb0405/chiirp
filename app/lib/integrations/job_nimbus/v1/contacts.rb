# frozen_string_literal: true

# app/lib/integrations/job_nimbus/v1/contacts.rb
module Integrations
  module JobNimbus
    module V1
      module Contacts
        # jn_client.contact(String)
        def contact(jnid = '')
          reset_attributes
          @result = {}

          if jnid.blank?
            @message = 'JobNimbus contact ID is required.'
            return @result
          end

          jobnimbus_request(
            body:                  nil,
            error_message_prepend: 'Integrations::JobNimbus::V1::Contacts.contact',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/contacts/#{jnid}"
          )
        end

        # call JobNimbus API to retrieve contacts
        # jn_client.contacts(page_size: Integer, page_index: Integer)
        def contacts(args = {})
          reset_attributes
          @result = []

          page_size   = (args.dig(:page_size) || 25).to_i
          page_index  = (args.dig(:page_index) || 0).to_i

          jobnimbus_request(
            body:                  nil,
            error_message_prepend: 'Integrations::JobNimbus::V1::Contacts.contacts',
            method:                'get',
            params:                {
              size: page_size,
              from: page_index
            },
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/contacts"
          )
        end

        # call JobNimbus API to retrieve the number of contacts
        # jn_client.contacts_count
        def contacts_count
          reset_attributes
          @result = {}

          @result = jobnimbus_request(
            body:                  nil,
            error_message_prepend: 'Integrations::JobNimbus::V1::Contacts.contacts_count',
            method:                'get',
            params:                {
              limit:     1,
              pageIndex: 0
            },
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/contacts"
          ).dig(:count) || 0
        end

        # parse/normalize Contact data from webhook
        def parse_contact_from_webhook(args = {})
          jn_contact = case args.dig(:type).to_s
                       when 'contact'
                         args
                       when 'estimate', 'job', 'invoice', 'workorder', 'task'

                         if (contact_jnid = (args.dig(:primary, :id) || args.dig(:related)&.find { |r| r.dig(:type).to_s == 'contact' }&.dig(:id)).to_s)
                           self.contact(contact_jnid)
                         else
                           {}
                         end
                       else
                         {}
                       end

          response = {
            id:              jn_contact.dig(:jnid).to_s,
            company:         jn_contact.dig(:company).to_s,
            firstname:       jn_contact.dig(:first_name).to_s,
            lastname:        jn_contact.dig(:last_name).to_s,
            address_01:      jn_contact.dig(:address_line1).to_s,
            address_02:      jn_contact.dig(:address_line2).to_s,
            city:            jn_contact.dig(:city).to_s,
            state:           jn_contact.dig(:state_text).to_s,
            zipcode:         jn_contact.dig(:zip).to_s,
            email:           jn_contact.dig(:email).to_s,
            status:          jn_contact.dig(:status_name).to_s,
            sales_rep:       jn_contact.dig(:sales_rep).to_s,
            sales_rep_name:  jn_contact.dig(:sales_rep_name).to_s,
            sales_rep_email: jn_contact.dig(:sales_rep_email).to_s,
            phones:          {}
          }

          response[:phones][jn_contact[:mobile_phone].to_s] = 'mobile' if jn_contact.dig(:mobile_phone).present?
          response[:phones][jn_contact[:home_phone].to_s]   = 'home' if jn_contact.dig(:home_phone).present?
          response[:phones][jn_contact[:work_phone].to_s]   = 'work' if jn_contact.dig(:work_phone).present?
          response[:phones][jn_contact[:fax_number].to_s]   = 'fax' if jn_contact.dig(:fax_number).present?

          response
        end

        # push Contact into JobNimbus contacts
        # jn_client.push_contact_to_jobnimbus(contact: Contact)
        def push_contact_to_jobnimbus(args = {})
          contact = args.dig(:contact)
          @result = {}

          unless contact.is_a?(Hash)
            @message = 'Contact data is required.'
            return @result
          end

          body = {
            first_name:    contact.dig(:firstname).to_s,
            last_name:     contact.dig(:lastname).to_s,
            email:         contact.dig(:email).to_s,
            address_line1: contact.dig(:address1).to_s,
            address_line2: contact.dig(:address2).to_s,
            city:          contact.dig(:city).to_s,
            state_text:    contact.dig(:state).to_s,
            zip:           contact.dig(:zipcode).to_s,
            company:       contact.dig(:companyname).to_s
          }

          contact.dig(:phones) || {}.each do |label, number|
            body[:mobile_phone] = number if label.include?('mobile')
            body[:home_phone]   = number if label.include?('home')
            body[:work_phone]   = number if label.include?('work')
            body[:fax_number]   = number if label.include?('fax')
          end

          jobnimbus_request(
            body:,
            error_message_prepend: 'Integrations::JobNimbus::V1::Contacts.push_contact_to_jobnimbus',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{base_api_version}/contacts"
          )
        end
      end
    end
  end
end
