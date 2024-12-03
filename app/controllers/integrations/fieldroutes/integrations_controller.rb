# frozen_string_literal: true

# app/controllers/integrations/fieldroutes/integrations_controller.rb
module Integrations
  module Fieldroutes
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[auth_code endpoint]
      before_action :authenticate_user!, except: %i[auth_code endpoint]
      before_action :authorize_user!, except: %i[auth_code endpoint]
      before_action :client_api_integration, except: %i[auth_code endpoint]
      before_action :client_api_integration_events, except: %i[auth_code endpoint]

      # (GET/POST) FieldRoutes webhook endpoint
      # /integrations/fieldroutes/endpoint
      # integrations_fieldroutes_endpoint_path
      # integrations_fieldroutes_endpoint_url
      def endpoint
        unsafe_params = JSON.parse(params&.to_unsafe_hash&.keys&.first || '{}')&.deep_symbolize_keys

        if (client_api_integration = ClientApiIntegration.joins(:client).where('clients.data @> ?', { active: true }.to_json).find_by(client_id: unsafe_params.dig(:client_id).to_i, target: 'fieldroutes', name: ''))
          "Integrations::Fieldroutes::V#{client_api_integration.data.dig('credentials', 'version')}::ProcessEventJob".constantize.perform_now(
            client_api_integration_id: client_api_integration.id,
            client_id:                 unsafe_params.dig(:client_id).to_i,
            event_id:                  unsafe_params.dig(:event_id).to_s,
            process_events:            true,
            raw_params:                unsafe_params
          )
          render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
        else
          render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
        end
      end
      # example FieldRoutes "Appointment Status" webhook payload
      # {
      #   client_id:          '1',
      #   event:              'appointment_status_change',
      #   customerID:         '18748',
      #   fname:              'Govardhan',
      #   lname:              'Muthineni',
      #   companyName:        '',
      #   address:            '26855 North 72nd Lane',
      #   city:               'Peoria',
      #   state:              'AZ',
      #   zip:                '85383',
      #   email:              'Vardhan128US@gmail.com',
      #   billingCompanyName: '',
      #   billingFName:       'Govardhan',
      #   billingLName:       'Muthineni',
      #   billingAddress:     '26855 North 72nd Lane',
      #   billingCity:        'Peoria',
      #   billingState:       'AZ',
      #   billingZip:         '85383',
      #   totalDue:           '0.00',
      #   age:                '{{age}}',
      #   serviceType:        '541',
      #   serviceDate:        '2024-07-15',
      #   description:        'Pest',
      #   serviceDescription: 'Pest',
      #   phone1:             '9092674961',
      #   phone2:             '',
      #   officeID:           '2',
      #   servicedBy:         '1367',
      #   serviceStartTime:   '8:00 AM',
      #   serviceEndTime:     '8:00 PM',
      #   building:           '',
      #   unitNumber:         '',
      #   salesRep:           'Field Routes',
      #   salesRep2:          '',
      #   salesRep3:          '',
      #   techName:           'Gerald  Chavez',
      #   appointmentID:      '148203',
      #   techPhone:          '7604888459',
      #   techEmail:          'gecchavez79@yahoo.com',
      #   officeName:         'Bucksworth - Phoenix Office',
      #   subscriptionID:     '17071'
      # }
      # example FieldRoutes "AR" webhook payload
      # {
      #   client_id:          '1',
      #   event:              'ar',
      #   customerID:         '10119',
      #   fname:              'Jas',
      #   lname:              'Dhillon',
      #   companyName:        '',
      #   address:            '28897 N 131st Drive',
      #   city:               'Peoria',
      #   state:              'AZ',
      #   zip:                '85383',
      #   email:              'kuk.dhillon@gmail.com',
      #   billingCompanyName: '',
      #   billingFName:       'Jagdeep',
      #   billingLName:       'S Dhillon',
      #   billingAddress:     '28897 N 131st Drive',
      #   billingCity:        'Peoria',
      #   billingState:       'AZ',
      #   billingZip:         '85383',
      #   totalDue:           '{{totalDue}}',
      #   age:                '{{age}}',
      #   responsibleBalance: '122.81',
      #   overdueDays:        '7'
      # }
      # example FieldRoutes "Subscription Due for Service" webhook payload
      # {
      #   age:                '{{age}}',
      #   zip:                '85132',
      #   city:               'Florence',
      #   email:              '',
      #   event:              'subscription_due_for_service',
      #   fname:              'Jennifer',
      #   lname:              'Smith',
      #   state:              'AZ',
      #   address:            '2255 N Smithsonian Dr',
      #   dueDate:            '2024-08-23',
      #   totalDue:           '{{totalDue}}',
      #   client_id:          '1',
      #   dateAdded:          'Apr, 22nd 2024',
      #   billingZip:         '85132',
      #   customerID:         '22320',
      #   annualValue:        '95',
      #   billingCity:        'Florence',
      #   companyName:        '',
      #   billingFName:       'Jennifer',
      #   billingLName:       'Smith',
      #   billingState:       'AZ',
      #   contractValue:      '265.00',
      #   dateCancelled:      '',
      #   billingAddress:     '2255 N Smithsonian Dr',
      #   subscriptionID:     '19222',
      #   billingCompanyName: '',
      #   serviceDescription: 'BLWeed'
      # }

      # (GET) show FieldRoutes integration overview screen
      # /integrations/fieldroutes
      # integrations_fieldroutes_path
      # integrations_fieldroutes_url
      def show
        client_api_integration = current_user.client.client_api_integrations.find_by(target: 'fieldroutes', name: '')

        path = if (version = client_api_integration&.data&.dig('credentials', 'version')).present?
                 send(:"integrations_fieldroutes_v#{version}_path")
               else
                 send(:"integrations_fieldroutes_v#{Integration::Fieldroutes::Base::CURRENT_VERSION}_path")
               end

        respond_to do |format|
          format.js { render js: "window.location = '#{path}'" and return false }
          format.html { redirect_to path and return false }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('fieldroutes')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access FieldRoutes Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'fieldroutes', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_events
        return if (@client_api_integration_events = current_user.client.client_api_integrations.find_or_create_by(target: 'fieldroutes', name: 'events'))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def complete_oauth2_connection_flow
        if oauth2_connection_completed_when_started_from_chiirp || oauth2_connection_completed_when_started_from_fieldroutes
          sweetalert_success('Success!', 'Connection to FieldRoutes was completed successfully.', '', { persistent: 'OK' })
        else
          disconnect_incomplete_connection
          sweetalert_error('Unathorized Access!', 'Unable to locate an account with FieldRoutes credentials received. Please contact your account admin.', '', { persistent: 'OK' })
        end
      end

      def disconnect_incomplete_connection
        sanitized_params = params_auth_code

        jb_client = "Integrations::FieldRoutes::V#{Integration::Fieldroutes::Base::CURRENT_VERSION}::Base".constantize.new({})
        jb_client.request_access_token(sanitized_params.dig(:code))

        return unless jb_client.success?

        jb_client = "Integrations::FieldRoutes::V#{Integration::Fieldroutes::Base::CURRENT_VERSION}::Base".constantize.new(jb_client.result)
        jb_client.disconnect_account
      end

      def oauth2_connection_completed_when_started_from_chiirp
        sanitized_params = params_auth_code

        sanitized_params.dig(:state).present? && (@client_api_integration = ClientApiIntegration.find_by('data @> ?', { auth_code: sanitized_params[:state] }.to_json)) &&
          sanitized_params.dig(:code).present? && "Integration::FieldRoutes::V#{Integration::Fieldroutes::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
          "Integration::FieldRoutes::V#{Integration::Fieldroutes::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_account
      end

      def oauth2_connection_completed_when_started_from_fieldroutes
        sanitized_params = params_auth_code

        sanitized_params.dig(:state).blank? && (@client_api_integration = current_user&.client&.client_api_integrations&.find_or_create_by(target: 'fieldroutes', name: '')) &&
          sanitized_params.dig(:code).present? && "Integration::FieldRoutes::V#{Integration::Fieldroutes::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
          "Integration::FieldRoutes::V#{Integration::Fieldroutes::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_account
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
# example FieldRoutes JSON configuration
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
