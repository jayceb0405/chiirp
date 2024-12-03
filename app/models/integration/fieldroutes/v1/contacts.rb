# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/contacts.rb
module Integration
  module Fieldroutes
    module V1
      module Contacts
        # find or create a Contact based on incoming webhook data
        # Integration::Fieldroutes::V1::Contacts.contact()
        def contact(**args)
          return nil if Integer(args.dig(:client_id), exception: false).blank?

          phones = {}
          phones[args.dig(:phone1).to_s.clean_phone] = 'Mobile' if args.dig(:phone1).to_s.tr('^0-9', '').length == 10
          phones[args.dig(:phone2).to_s.clean_phone] = 'Mobile' if args.dig(:phone2).to_s.tr('^0-9', '').length == 10

          return nil unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args.dig(:client_id).to_i, phones:, emails: args.dig(:email).presence&.split(';')&.map(&:strip)&.compact_blank, ext_refs: { 'fieldroutes' => args.dig(:customerID).presence }))

          contact.update(
            firstname:   (args.dig(:fname).presence || contact.firstname).to_s,
            lastname:    (args.dig(:lname).presence || contact.lastname).to_s,
            companyname: (args.dig(:billingCompanyName).presence || contact.companyname).to_s,
            address1:    (args.dig(:billingAddress).presence || contact.address1).to_s,
            city:        (args.dig(:billingCity).presence || contact.city).to_s,
            state:       (args.dig(:billingState).presence || contact.state).to_s,
            zipcode:     (args.dig(:billingZip).presence || contact.zipcode).to_s
          )

          contact
        end
        # example of pertinent webhook data required to define a Contact
        # {
        #   client_id:          '1',
        #   customerID:         '10119',
        #   fname:              'Jas',
        #   lname:              'Dhillon',
        #   billingCompanyName: '',
        #   billingFName:       'Govardhan',
        #   billingLName:       'Muthineni',
        #   billingAddress:     '26855 North 72nd Lane',
        #   billingCity:        'Peoria',
        #   billingState:       'AZ',
        #   billingZip:         '85383',
        #   email:              'AGomez1@drhorton.com; JBMaples@drhorton.com; KPHicks@drhorton.com; VJGonzalez@drhorton.com',
        #   phone1:             '9092674961',
        #   phone2:             '',
        # }
      end
    end
  end
end
