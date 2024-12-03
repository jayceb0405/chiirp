# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/base.rb
module Integration
  module Fieldroutes
    module V1
      class Base < Integration::Fieldroutes::Base
        attr_reader :error, :message, :result, :success
        alias success? success

        include Integration::Fieldroutes::V1::Contacts
        include Integration::Fieldroutes::V1::Customers
        include Integration::Fieldroutes::V1::Employees
        include Integration::Fieldroutes::V1::ImportContacts
        include Integration::Fieldroutes::V1::Jobs
        include Integration::Fieldroutes::V1::Offices
        include Integration::Fieldroutes::V1::Subscriptions

        EVENT_TYPE_OPTIONS = [
          ['Appointment Status Change', 'appointment_status_change'],
          # ['Accounts Receivable', 'ar'],
          # ['Subscription Due For Service', 'subscription_due_for_service'],
          ['Subscription Status', 'subscription_status']
        ].freeze
        IMPORT_BLOCK_COUNT = 50

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'fieldroutes', name: ''); fr_model = Integration::Fieldroutes::V1::Base.new(client_api_integration); fr_model.valid_credentials?; fr_client = Integrations::FieldRoutes::V1::Base.new(client_api_integration.credentials)

        # fr_model = Integration::Fieldroutes::V1::Base.new()
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          reset_attributes

          self.client_api_integration = client_api_integration
        end

        def valid_credentials?
          @fr_client.valid_credentials?
        end

        private

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'fieldroutes', name: '')
                                    end

          @client    = @client_api_integration.client
          @fr_client = Integrations::FieldRoutes::V1::Base.new(@client_api_integration.credentials)
        end

        def put_attributes
          Rails.logger.info "@success: #{@success.inspect} / @error: #{@error.inspect} / @message: #{@message.inspect} / @result: #{@result} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        end

        def reset_attributes
          @error   = 0
          @message = ''
          @result  = nil
          @success = false
        end

        def update_attributes_from_client
          @error   = @fr_client.error
          @message = @fr_client.message
          @result  = @fr_client.result
          @success = @fr_client.success?
        end
      end
    end
  end
end
