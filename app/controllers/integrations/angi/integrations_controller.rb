# frozen_string_literal: true

# app/controllers/integrations/angi/integrations_controller.rb
module Integrations
  module Angi
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[auth_code endpoint]
      before_action :authenticate_user!, except: %i[auth_code endpoint]
      before_action :authorize_user!, except: %i[auth_code endpoint]
      before_action :client_api_integration, except: %i[auth_code endpoint]
      before_action :client_api_integration_events, except: %i[auth_code endpoint]

      # (GET/POST) Angi webhook endpoint
      # /integrations/angi/:id/endpoint
      # endpoint_integrations_angi_path(:id)
      # endpoint_integrations_angi_url(:id)
      def endpoint
        id = params.permit(:id).dig(:id)

        if (client_api_integration_event = ClientApiIntegration.where(target: 'angi', name: 'events').joins(:client).where('clients.data @> ?', { active: true }.to_json).find_by("client_api_integrations.data -> 'events' ? :event_id", event_id: id)) &&
           (client_api_integration = client_api_integration_event.client.client_api_integrations.find_by(target: 'angi', name: ''))
          "Integrations::Angi::V#{client_api_integration.data.dig('credentials', 'version').presence || Integration::Angi::Base::CURRENT_VERSION}::ProcessEventJob".constantize.perform_later(
            client_api_integration_id: client_api_integration.id,
            client_id:                 client_api_integration.client_id,
            event_id:                  id,
            process_events:            true,
            raw_params:                params&.to_unsafe_hash
          )
          render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
        else
          render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
        end
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
      #   srOid:               297_323_861,
      #   leadOid:             559_629_987,
      #   fee:                 27.56,
      #   taskName:            'Water Heater - Repair or Service',
      #   comments:            'Customer did not provide additional comments. Please contact the customer to discuss the details of this project.',
      #   matchType:           'Lead',
      #   leadDescription:     'Standard',
      #   spEntityId:          22_548_861,
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

      # (GET) show Angi integration overview screen
      # /integrations/angi
      # integrations_angi_path
      # integrations_angi_url
      def show
        client_api_integration = current_user.client.client_api_integrations.find_by(target: 'angi', name: '')

        path = if (version = client_api_integration&.data&.dig('credentials', 'version')).present?
                 send(:"integrations_angi_v#{version}_path")
               else
                 send(:"integrations_angi_v#{Integration::Angi::Base::CURRENT_VERSION}_path")
               end

        respond_to do |format|
          format.js { render js: "window.location = '#{path}'" and return false }
          format.html { redirect_to path and return false }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('angi')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Angi Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'angi', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_events
        return if (@client_api_integration_events = current_user.client.client_api_integrations.find_or_create_by(target: 'angi', name: 'events'))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def complete_oauth2_connection_flow
        if oauth2_connection_completed_when_started_from_chiirp || oauth2_connection_completed_when_started_from_Angi
          sweetalert_success('Success!', 'Connection to Angi was completed successfully.', '', { persistent: 'OK' })
        else
          disconnect_incomplete_connection
          sweetalert_error('Unathorized Access!', 'Unable to locate an account with Angi credentials received. Please contact your account admin.', '', { persistent: 'OK' })
        end
      end

      def disconnect_incomplete_connection
        sanitized_params = params_auth_code

        jb_client = "Integrations::Angi::V#{Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new({})
        jb_client.request_access_token(sanitized_params.dig(:code))

        return unless jb_client.success?

        jb_client = "Integrations::Angi::V#{Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new(jb_client.result)
        jb_client.disconnect_account
      end

      def oauth2_connection_completed_when_started_from_chiirp
        sanitized_params = params_auth_code

        sanitized_params.dig(:state).present? && (@client_api_integration = ClientApiIntegration.find_by('data @> ?', { auth_code: sanitized_params[:state] }.to_json)) &&
          sanitized_params.dig(:code).present? && "Integration::Angi::V#{Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
          "Integration::Angi::V#{Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_account
      end

      def oauth2_connection_completed_when_started_from_Angi
        sanitized_params = params_auth_code

        sanitized_params.dig(:state).blank? && (@client_api_integration = current_user&.client&.client_api_integrations&.find_or_create_by(target: 'angi', name: '')) &&
          sanitized_params.dig(:code).present? && "Integration::Angi::V#{Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
          "Integration::Angi::V#{Integration::Angi::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_account
      end

      def params_endpoint
        params.permit(:client_id)
      end

      def params_auth_code
        params.permit(:code, :state)
      end
    end
  end
end
# example Angi JSON configuration
##### Appointment Status: #####
# {{loginLink}} - Link to customer's FieldPortals account
# {{portalURL}} - Link to FieldPortals
# {{username}} - FieldPortals Account Number
# {{customerID}} - Customer ID
# {{customerNumber}} - Customer Number
# {{fname}} - Customer First Name
# {{lname}} - Customer Last Name
# {{companyName}} - Customer Company Name
# {{address}} - Customer Address
# {{city}} - Customer City
# {{state}} - Customer State
# {{zip}} - Customer Zip
# {{email}} - Customer Email
# {{billingCompanyName}} - Billing Company Name
# {{billingFName}} - Billing First name
# {{billingLName}} - Billing Last Name
# {{billingAddress}} - Billing Address
# {{billingCity}} - Billing City
# {{billingState}} - Billing State
# {{billingZip}} - Billing Zip
# {{totalDue}} - Total Amount Due
# {{age}} - Customer Balance Age
# {{serviceType}} - service type ID
# {{serviceDate}} - appointment service date
# {{description}} - appointment service type
# {{serviceDescription}} - service type (e.g. General Pest) or service plan with service (e.g. Annual Lawn Care - Fertilization) subscription description, or stand-alone if no subscription
# {{phone1}} - customer phone 1
# {{phone2}} - customer phone 2
# {{officeID}} - officeID of the appointment
# {{servicedBy}} - employeeID that serviced the appointment
# {{serviceStartTime}} - scheduled start time for the appointment
# {{serviceEndTime}} - scheduled end time for the appointment
# {{building}} - building number in a multi-unit property. Note: Blank if not applicable
# {{unitNumber}} - unit number in a multi-unit property. Note: Blank if not applicable
# {{salesRep}} - Sales Rep that sold Subscription. Note: Blank if not applicable. (ex. for Stand-Alone Appointments)
# {{salesRep2}} - Secondary Sales Rep that sold Subscription. Note: Blank if not applicable. (ex. for Stand-Alone Appointments)
# {{salesRep3}} - Third Sales Rep that sold Subscription. Note: Blank if not applicable. (ex. disabled Sales Rep 3 preference)
# {{techName}} - Name of technician assigned to the appointment.
# {{appointmentID}} - AppointmentID.
# {{techPhone}} - Phone of technician assigned to the appointment.
# {{techEmail}} - Email of technician assigned to the appointment.
# {{officeName}} - Office Name.
# {{subscriptionID}} - SubscriptionID of the appointment.
# "{\"client_id\":\"1\",\"event\":\"appointment_status_change\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"serviceType\":\"{{serviceType}}\",\"serviceDate\":\"{{serviceDate}}\",\"description\":\"{{description}}\",\"serviceDescription\":\"{{serviceDescription}}\",\"phone1\":\"{{phone1}}\",\"phone2\":\"{{phone2}}\",\"officeID\":\"{{officeID}}\",\"servicedBy\":\"{{servicedBy}}\",\"serviceStartTime\":\"{{serviceStartTime}}\",\"serviceEndTime\":\"{{serviceEndTime}}\",\"building\":\"{{building}}\",\"unitNumber\":\"{{unitNumber}}\",\"salesRep\":\"{{salesRep}}\",\"salesRep2\":\"{{salesRep2}}\",\"salesRep3\":\"{{salesRep3}}\",\"techName\":\"{{techName}}\",\"appointmentID\":\"{{appointmentID}}\",\"techPhone\":\"{{techPhone}}\",\"techEmail\":\"{{techEmail}}\",\"officeName\":\"{{officeName}}\",\"subscriptionID\":\"{{subscriptionID}}\"}"
##### AR: #####
# {{loginLink}} - Link to customer's FieldPortals account
# {{portalURL}} - Link to FieldPortals
# {{username}} - FieldPortals Account Number
# {{customerID}} - Customer ID
# {{customerNumber}} - Customer Number
# {{fname}} - Customer First Name
# {{lname}} - Customer Last Name
# {{companyName}} - Customer Company Name
# {{address}} - Customer Address
# {{city}} - Customer City
# {{state}} - Customer State
# {{zip}} - Customer Zip
# {{email}} - Customer Email
# {{billingCompanyName}} - Billing Company Name
# {{billingFName}} - Billing First name
# {{billingLName}} - Billing Last Name
# {{billingAddress}} - Billing Address
# {{billingCity}} - Billing City
# {{billingState}} - Billing State
# {{billingZip}} - Billing Zip
# {{totalDue}} - Total Amount Due
# {{age}} - Customer Balance Age
# {{responsibleBalance}} - customer responsible balance
# {{overdueDays}} - days past due
# "{\"client_id\":\"1\",\"event\":\"ar\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"phone1\":\"{{phone1}}\",\"phone2\":\"{{phone2}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"responsibleBalance\":\"{{responsibleBalance}}\",\"overdueDays\":\"{{overdueDays}}\"}"
##### Renewal: #####
# {{loginLink}} - Link to customer's FieldPortals account
# {{portalURL}} - Link to FieldPortals
# {{username}} - FieldPortals Account Number
# {{customerID}} - Customer ID
# {{customerNumber}} - Customer Number
# {{fname}} - Customer First Name
# {{lname}} - Customer Last Name
# {{companyName}} - Customer Company Name
# {{address}} - Customer Address
# {{city}} - Customer City
# {{state}} - Customer State
# {{zip}} - Customer Zip
# {{email}} - Customer Email
# {{billingCompanyName}} - Billing Company Name
# {{billingFName}} - Billing First name
# {{billingLName}} - Billing Last Name
# {{billingAddress}} - Billing Address
# {{billingCity}} - Billing City
# {{billingState}} - Billing State
# {{billingZip}} - Billing Zip
# {{totalDue}} - Total Amount Due
# {{age}} - Customer Balance Age
# {{billingCustomerNumber}} - Billing Customer Number
# {{propertyType}} - PropertyType
# {{subscriptionID}} - Subscription ID
# {{description}} - Subscription
# {{subscriptionStatus}} - Subscription Status
# {{renewalDate}} - Renewal Date
# {{nextRenewalPeriodStart}} - Renewal Period Start
# {{nextRenewalPeriodEnd}} - Renewal Period End
# {{recurringCharge}} - Recurring Subtotal
# {{recurringTotal}} - Recurring Total
# {{renewalPeriodSubtotal}} - Renewal Period Subtotal
# {{renewalPeriodTotal}} - Renewal Period Total (Includes Tax)
# {{nextBillingDate}} - Next Billing Date
# {{expirationDate}} - Expiration Date
# {{lastRenewalNoticeDate}} - Last Renewal Notice Sent
# {{initialServiceDate}} - Initial Service Date
# {{balance}} - Balance
# {{dueDate}} - Due Date
# {{frequency}} - Frequency
# {{agreementLength}} - Agreement Length
# {{sentricon}} - Is Sentricon
# {{sadDate}} - SAD Date
# {{renewalLink}} - For email creates a link with text "Please click here to renew!" For SMS or Voice displays url. Not available for printed notices, snail mail notices or http hooks.
# "{\"client_id\":\"1\",\"event\":\"renewal\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"billingCustomerNumber\":\"{{billingCustomerNumber}}\",\"propertyType\":\"{{propertyType}}\",\"subscriptionID\":\"{{subscriptionID}}\",\"description\":\"{{description}}\",\"subscriptionStatus\":\"{{subscriptionStatus}}\",\"renewalDate\":\"{{renewalDate}}\",\"nextRenewalPeriodStart\":\"{{nextRenewalPeriodStart}}\",\"nextRenewalPeriodEnd\":\"{{nextRenewalPeriodEnd}}\",\"recurringCharge\":\"{{recurringCharge}}\",\"recurringTotal\":\"{{recurringTotal}}\",\"renewalPeriodSubtotal\":\"{{renewalPeriodSubtotal}}\",\"renewalPeriodTotal\":\"{{renewalPeriodTotal}}\",\"nextBillingDate\":\"{{nextBillingDate}}\",\"expirationDate\":\"{{expirationDate}}\",\"lastRenewalNoticeDate\":\"{{lastRenewalNoticeDate}}\",\"initialServiceDate\":\"{{initialServiceDate}}\",\"balance\":\"{{balance}}\",\"dueDate\":\"{{dueDate}}\",\"frequency\":\"{{frequency}}\",\"agreementLength\":\"{{agreementLength}}\",\"sentricon\":\"{{sentricon}}\",\"sadDate\":\"{{sadDate}}\",\"renewalLink\":\"{{renewalLink}}\"}"
##### Subscription Due for Service: #####
# {{loginLink}} - Link to customer's FieldPortals account
# {{portalURL}} - Link to FieldPortals
# {{username}} - FieldPortals Account Number
# {{customerID}} - Customer ID
# {{customerNumber}} - Customer Number
# {{fname}} - Customer First Name
# {{lname}} - Customer Last Name
# {{companyName}} - Customer Company Name
# {{address}} - Customer Address
# {{city}} - Customer City
# {{state}} - Customer State
# {{zip}} - Customer Zip
# {{email}} - Customer Email
# {{billingCompanyName}} - Billing Company Name
# {{billingFName}} - Billing First name
# {{billingLName}} - Billing Last Name
# {{billingAddress}} - Billing Address
# {{billingCity}} - Billing City
# {{billingState}} - Billing State
# {{billingZip}} - Billing Zip
# {{totalDue}} - Total Amount Due
# {{age}} - Customer Balance Age
# {{customerID}} - customer ID
# {{subscriptionID}} - subscription ID
# {{serviceDescription}} - service type (e.g. General Pest) or service plan with service (e.g. Annual Lawn Care - Fertilization) subscription description
# {{dateCancelled}} - subscription canceled date
# {{dateAdded}} - subscription added date
# {{dueDate}} - date subscription due
# {{contractValue}} - total value for the first year of service for a service type
# {{annualValue}} - For a service type, this is the total annual value of services after the initial year. For a service plan, this is the annual sum of service charges within the plan and does not include any services that were skipped or opted-out.
# "{\"client_id\":\"1\",\"event\":\"subscription_due_for_service\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"customerID\":\"{{customerID}}\",\"subscriptionID\":\"{{subscriptionID}}\",\"serviceDescription\":\"{{serviceDescription}}\",\"dateCancelled\":\"{{dateCancelled}}\",\"dateAdded\":\"{{dateAdded}}\",\"dueDate\":\"{{dueDate}}\",\"contractValue\":\"{{contractValue}}\",\"annualValue\":\"{{annualValue}}\"}"
##### Subscription Status: #####
# {{loginLink}} - Link to customer's FieldPortals account
# {{portalURL}} - Link to FieldPortals
# {{username}} - FieldPortals Account Number
# {{customerID}} - Customer ID
# {{customerNumber}} - Customer Number
# {{fname}} - Customer First Name
# {{lname}} - Customer Last Name
# {{companyName}} - Customer Company Name
# {{address}} - Customer Address
# {{city}} - Customer City
# {{state}} - Customer State
# {{zip}} - Customer Zip
# {{email}} - Customer Email
# {{billingCompanyName}} - Billing Company Name
# {{billingFName}} - Billing First name
# {{billingLName}} - Billing Last Name
# {{billingAddress}} - Billing Address
# {{billingCity}} - Billing City
# {{billingState}} - Billing State
# {{billingZip}} - Billing Zip
# {{totalDue}} - Total Amount Due
# {{age}} - Customer Balance Age
# {{customerID}} - customer ID
# {{subscriptionID}} - subscription ID
# {{description}} - service subscription
# {{dateCancelled}} - subscription date canceled
# {{dateAdded}} - date subscription added
# {{agreementLink}} - link to the subscription agreement in the customer portal
# {{contractValue}} - total value for the first year of service for a service type
# {{annualValue}} - For a service type, this is the total annual value of services after the initial year. For a service plan, this is the annual sum of service charges within the plan and does not include any services that were skipped or opted-out.
# {{phone1}} - customer phone 1
# {{phone2}} - customer phone 2
# {{conditions30}} - conditions with upsells found in the last 30 days
# "{\"client_id\":1,\"event\":\"subscription_status\",\"customerNumber\":\"{{customerNumber}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"customerID\":\"{{customerID}}\",\"subscriptionID\":\"{{subscriptionID}}\",\"description\":\"{{description}}\",\"dateCancelled\":\"{{dateCancelled}}\",\"dateAdded\":\"{{dateAdded}}\",\"agreementLink\":\"{{agreementLink}}\",\"contractValue\":\"{{contractValue}}\",\"annualValue\":\"{{annualValue}}\",\"phone1\":\"{{phone1}}\",\"phone2\":\"{{phone2}}\",\"conditions30\":\"{{conditions30}}\"}"
