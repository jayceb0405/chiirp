# frozen_string_literal: true

# app/controllers/integrations/angi/v1/instructions_controller.rb
module Integrations
  module Angi
    module V1
      class InstructionsController < Angi::V1::IntegrationsController
        # (GET) show instructions page for Angi integration
        # /integrations/angi/v1/instructions
        # integrations_angi_v1_instructions_path
        # integrations_angi_v1_instructions_url
        def show; end
      end
    end
  end
end

# sample Angi webhook JSON payloads
# Appointment Status:
# "{\"client_id\":\"1\",\"event\":\"appointment_status_change\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"serviceType\":\"{{serviceType}}\",\"serviceDate\":\"{{serviceDate}}\",\"description\":\"{{description}}\",\"serviceDescription\":\"{{serviceDescription}}\",\"phone1\":\"{{phone1}}\",\"phone2\":\"{{phone2}}\",\"officeID\":\"{{officeID}}\",\"servicedBy\":\"{{servicedBy}}\",\"serviceStartTime\":\"{{serviceStartTime}}\",\"serviceEndTime\":\"{{serviceEndTime}}\",\"building\":\"{{building}}\",\"unitNumber\":\"{{unitNumber}}\",\"salesRep\":\"{{salesRep}}\",\"salesRep2\":\"{{salesRep2}}\",\"salesRep3\":\"{{salesRep3}}\",\"techName\":\"{{techName}}\",\"appointmentID\":\"{{appointmentID}}\",\"techPhone\":\"{{techPhone}}\",\"techEmail\":\"{{techEmail}}\",\"officeName\":\"{{officeName}}\",\"subscriptionID\":\"{{subscriptionID}}\"}"
# AR:
# "{\"client_id\":\"1\",\"event\":\"ar\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"responsibleBalance\":\"{{responsibleBalance}}\",\"overdueDays\":\"{{overdueDays}}\"}"
# Renewal:
# "{\"client_id\":\"1\",\"event\":\"renewal\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"billingCustomerNumber\":\"{{billingCustomerNumber}}\",\"propertyType\":\"{{propertyType}}\",\"subscriptionID\":\"{{subscriptionID}}\",\"description\":\"{{description}}\",\"subscriptionStatus\":\"{{subscriptionStatus}}\",\"renewalDate\":\"{{renewalDate}}\",\"nextRenewalPeriodStart\":\"{{nextRenewalPeriodStart}}\",\"nextRenewalPeriodEnd\":\"{{nextRenewalPeriodEnd}}\",\"recurringCharge\":\"{{recurringCharge}}\",\"recurringTotal\":\"{{recurringTotal}}\",\"renewalPeriodSubtotal\":\"{{renewalPeriodSubtotal}}\",\"renewalPeriodTotal\":\"{{renewalPeriodTotal}}\",\"nextBillingDate\":\"{{nextBillingDate}}\",\"expirationDate\":\"{{expirationDate}}\",\"lastRenewalNoticeDate\":\"{{lastRenewalNoticeDate}}\",\"initialServiceDate\":\"{{initialServiceDate}}\",\"balance\":\"{{balance}}\",\"dueDate\":\"{{dueDate}}\",\"frequency\":\"{{frequency}}\",\"agreementLength\":\"{{agreementLength}}\",\"sentricon\":\"{{sentricon}}\",\"sadDate\":\"{{sadDate}}\",\"renewalLink\":\"{{renewalLink}}\"}"
# Subscription Due for Service:
# "{\"client_id\":\"1\",\"event\":\"subscription_due_for_service\",\"customerID\":\"{{customerID}}\",\"fname\":\"{{fname}}\",\"lname\":\"{{lname}}\",\"companyName\":\"{{companyName}}\",\"address\":\"{{address}}\",\"city\":\"{{city}}\",\"state\":\"{{state}}\",\"zip\":\"{{zip}}\",\"email\":\"{{email}}\",\"billingCompanyName\":\"{{billingCompanyName}}\",\"billingFName\":\"{{billingFName}}\",\"billingLName\":\"{{billingLName}}\",\"billingAddress\":\"{{billingAddress}}\",\"billingCity\":\"{{billingCity}}\",\"billingState\":\"{{billingState}}\",\"billingZip\":\"{{billingZip}}\",\"totalDue\":\"{{totalDue}}\",\"age\":\"{{age}}\",\"customerID\":\"{{customerID}}\",\"subscriptionID\":\"{{subscriptionID}}\",\"serviceDescription\":\"{{serviceDescription}}\",\"dateCancelled\":\"{{dateCancelled}}\",\"dateAdded\":\"{{dateAdded}}\",\"dueDate\":\"{{dueDate}}\",\"contractValue\":\"{{contractValue}}\",\"annualValue\":\"{{annualValue}}\"}"
