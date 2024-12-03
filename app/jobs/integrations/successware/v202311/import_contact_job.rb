# frozen_string_literal: true

# app/jobs/integrations/successware/v202311/import_contact_job.rb
module Integrations
  module Successware
    module V202311
      class ImportContactJob < ApplicationJob
        # Integrations::Successware::V202311::ImportContactJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Successware::V202311::ImportContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

        def initialize(**args)
          super

          @process          = (args.dig(:process).presence || 'successware_import_contact').to_s
          @reschedule_secs  = 0
        end

        # import Contacts from Successware clients
        # step 3 / import the Successware client
        # perform the ActiveJob
        #   (req) actions:              (Hash)
        #     see import_contact_actions
        #   (req) successware_customer: (Hash)
        #   (req) user_id:              (Integer)
        def perform(**args)
          super

          args = args.deep_symbolize_keys

          return unless args.dig(:actions).is_a?(Hash) && args.dig(:successware_customer).is_a?(Hash) && args.dig(:successware_customer).present?
          return unless args.dig(:user_id).to_i.positive? && (user = User.find_by(id: args[:user_id]))
          return unless (client_api_integration = user.client.client_api_integrations.find_by(target: 'successware', name: ''))
          return unless (sw_model = Integration::Successware::V202311::Base.new(client_api_integration)) && sw_model.valid_credentials?

          contact = nil

          phones = {}
          phones[args[:successware_customer].dig(:customer, :phoneNumber).to_s.tr('^0-9', '')] = 'mobile' if args[:successware_customer].dig(:customer, :phoneNumber).present?
          phones[args[:successware_customer].dig(:customer, :phone2).to_s.tr('^0-9', '')] = 'mobile' if args[:successware_customer].dig(:customer, :phone2).present?
          phones[args[:successware_customer].dig(:customer, :phone3).to_s.tr('^0-9', '')] = 'mobile' if args[:successware_customer].dig(:customer, :phone3).present?
          phones[args[:successware_customer].dig(:customer, :phone4).to_s.tr('^0-9', '')] = 'mobile' if args[:successware_customer].dig(:customer, :phone4).present?

          return unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones:, emails: [args[:successware_customer].dig(:customer, :email).presence].compact_blank, ext_refs: { 'successware' => args[:successware_customer].dig(:customer, :id).to_i }))

          contact.lastname       = (args[:successware_customer].dig(:customer, :lastName) || contact.lastname).to_s
          contact.firstname      = (args[:successware_customer].dig(:customer, :firstName) || contact.firstname).to_s
          contact.companyname    = (args[:successware_customer].dig(:customer, :companyName) || contact.companyname).to_s
          contact.address1       = (args[:successware_customer].dig(:serviceLocations)&.first&.dig(:address1) || contact.address1).to_s
          contact.address2       = (args[:successware_customer].dig(:serviceLocations)&.first&.dig(:address2) || contact.address2).to_s
          contact.city           = (args[:successware_customer].dig(:serviceLocations)&.first&.dig(:city) || contact.city).to_s
          contact.state          = (args[:successware_customer].dig(:serviceLocations)&.first&.dig(:state) || contact.state).to_s
          contact.zipcode        = (args[:successware_customer].dig(:serviceLocations)&.first&.dig(:zipCode) || contact.zipcode).to_s

          if contact.save
            sw_model.import_contact_actions(contact, args[:actions], args[:successware_customer].dig(:billingAccountOutput, :mainArBillingCustomer)&.first&.dig(:balanceDue).to_d)
          else
            JsonLog.info 'Integrations::Successware::V202311::ImportContactJob.perform', { contact:, errors: contact&.errors&.full_messages&.inspect || 'None' }, client_id: user.client_id, contact_id: contact.id, user_id: user.id
          end

          sw_model.import_contacts_remaining_update(args[:user_id])
        end
        # example Successware customer data received
        # {
        #   "id":"1716257030",
        #   "customer": {
        #     "id":"1716257030",
        #     "firstName":"Ching",
        #     "lastName":"Blackerby",
        #     "phoneNumber":"5556385822",
        #     "email":null,
        #     "leadSource":"Ref -O",
        #     "leadSourceId":"1716000552",
        #     "noEmail":false,
        #     "phone2":"555-638-5822",
        #     "phone3":null,
        #     "phone4":null,
        #     "leadSourceDescription":"Referred by others ???",
        #     "commercial":false,
        #     "companyName":null
        #   },
        #   "serviceLocations": [
        #     {
        #       "id":"1716257030",
        #       "address1":"6362 Rolling Dale Ct",
        #       "address2":null,
        #       "city":"Brewerton",
        #       "state":"NY",
        #       "zipCode":"13039",
        #       "type":"Residential",
        #       "companyName":null,
        #       "contractArBillingCustomerId":null
        #     }
        #   ],
        #   "primaryBillingAddress":null,
        #   "billingAccountOutput": {
        #     "mainArBillingCustomer": [
        #       {"balanceDue":0.0}
        #     ]
        #   }
        # }
      end
    end
  end
end
