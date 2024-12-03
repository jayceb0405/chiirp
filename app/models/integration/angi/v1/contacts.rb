# frozen_string_literal: true

# app/models/integration/angi/v1/contacts.rb
module Integration
  module Angi
    module V1
      module Contacts
        # find or create a Contact based on incoming webhook data
        # Integration::Angi::V1::Contacts.contact()
        #   (req) client_id:  (Integer)
        #   (req) raw_params: (Hash)
        def contact(**args)
          return nil if Integer(args.dig(:client_id), exception: false).blank?

          args.deep_symbolize_keys!

          return nil unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args.dig(:client_id).to_i, phones: collect_phones(args), emails: collect_emails(args), ext_refs: { 'angi' => args.dig(:raw_params, :leadOid).presence }))

          contact.update(
            firstname: (args.dig(:raw_params, :FirstName).presence || args.dig(:raw_params, :firstName).presence || contact.firstname).to_s,
            lastname:  (args.dig(:raw_params, :LastName).presence || args.dig(:raw_params, :lastName).presence || contact.lastname).to_s,
            address1:  (args.dig(:raw_params, :PostalAddress, :AddressFirstLine).presence || args.dig(:raw_params, :address).presence || contact.address1).to_s,
            address2:  (args.dig(:raw_params, :PostalAddress, :AddressSecondLine).presence || contact.address1).to_s,
            city:      (args.dig(:raw_params, :PostalAddress, :City).presence || args.dig(:raw_params, :city).presence || contact.city).to_s,
            state:     (args.dig(:raw_params, :PostalAddress, :State).presence || args.dig(:raw_params, :stateProvince).presence || contact.state).to_s,
            zipcode:   (args.dig(:raw_params, :PostalAddress, :PostalCode).presence || args.dig(:raw_params, :postalCode).presence || contact.zipcode).to_s
          )

          contact
        end
        # example Angi "Ad" webhook payload
        # {
        #   FirstName:      'Abbey',
        #   LastName:       'Johnson',
        #   PhoneNumber:    '6156797338',
        #   PostalAddress:  { AddressFirstLine: '7293 Cavalier Drive', AddressSecondLine: '', City: 'Nashville', State: 'TN', PostalCode: '37221' },
        #   Email:          'abbeyjohnson546@gmail.com',
        #   Source:         "Angie's List Quote Request",
        #   Description:    'Nashville - Install or Replace a Ductless Mini-split Air Conditioning System: I need a ductless mini split ac/heater installed in my basement on Tuesday November 19th, or sooner. It requires a permit.',
        #   Category:       'Heating and Air Conditioning',
        #   Urgency:        'NA',
        #   CorrelationId:  'abafdaf8-7f16-4adf-b4ca-c50a2c7a4e41',
        #   ALAccountId:    '7564906',
        #   TrustedFormUrl: 'https://cert.trustedform.com/991bb141df4fb943c6d70d786c983c31e9613d2b',
        #   client_id:      '4332',
        #   token:          '[FILTERED]'
        # }
        # example Angi "Lead" webhook payload
        # {
        #   name:                'HERLINDA ARRIAGA',
        #   firstName:           'HERLINDA',
        #   lastName:            'ARRIAGA',
        #   address:             'South Winston Place',
        #   city:                'Tulsa',
        #   stateProvince:       'OK',
        #   postalCode:          '74136',
        #   primaryPhone:        '9182616572',
        #   secondaryPhone:      nil,
        #   email:               'hma8521@gmail.com',
        #   srOid:               297323861,
        #   leadOid:             559629987,
        #   fee:                 27.56,
        #   taskName:            'Water Heater - Repair or Service',
        #   comments:            'Customer did not provide additional comments. Please contact the customer to discuss the details of this project.',
        #   matchType:           'Lead',
        #   leadDescription:     'Standard',
        #   spEntityId:          22548861,
        #   spCompanyName:       'Torch Service Company LLC',
        #   primaryPhoneDetails: { maskedNumber: false },
        #   interview:           [{ question: 'What kind of water heater do you want repaired?', answer: 'Not sure/other' },
        #                         { question: 'What is the problem with your water heater? (Choose all that apply)', answer: 'No hot water' },
        #                         { question: 'What is the heat source for the water heater?', answer: 'Electricity' },
        #                         { question: 'Location', answer: 'Home' },
        #                         { question: 'When do you need this work done?', answer: 'Urgent (1-2 days)' }],
        #   client_id:           '4144',
        #   token:               '[FILTERED]'
        # }

        private

        def collect_emails(args)
          [args.dig(:raw_params, :Email), args.dig(:raw_params, :email)].compact_blank
        end

        def collect_phones(args)
          response = {}

          response[args.dig(:raw_params, :PhoneNumber)] = 'mobile' if args.dig(:raw_params, :PhoneNumber).present?
          response[args.dig(:raw_params, :primaryPhone)] = 'mobile' if args.dig(:raw_params, :primaryPhone).present?
          response[args.dig(:raw_params, :secondaryPhone)] = 'mobile' if args.dig(:raw_params, :secondaryPhone).present?

          response
        end
      end
    end
  end
end
