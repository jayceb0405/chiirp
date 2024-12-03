# frozen_string_literal: true

# app/models/integration/angi/v1/base.rb
module Integration
  module Angi
    module V1
      class Base < Integration::Angi::Base
        attr_reader :error, :message, :result, :success
        alias success? success

        include Integration::Angi::V1::Contacts

        EVENT_TYPE_OPTIONS = [
          ['Angi Ads', 'ads'],
          ['Angi Leads', 'leads']
        ].freeze
        IMPORT_BLOCK_COUNT = 50

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'angi', name: ''); ag_model = Integration::Angi::V1::Base.new(client_api_integration); ag_model.valid_credentials?

        # ag_model = Integration::Angi::V1::Base.new()
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          reset_attributes

          self.client_api_integration = client_api_integration
        end

        def client_api_integration_events
          @client_api_integration_events ||= @client_api_integration.client.client_api_integrations.find_or_create_by(target: 'angi', name: 'events')
        end

        def event_count
          client_api_integration_events.events.length
        end

        def valid_credentials?
          true
        end

        private

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'angi', name: '')
                                    end

          @client = @client_api_integration.client
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
      end
    end
  end
end
