# frozen_string_literal: true

# app/models/integration/contractorcommerce/v1/base.rb
module Integration
  module Contractorcommerce
    module V1
      class Base
        include Integration::Contractorcommerce::V1::Events

        VERSION = '1'

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'contractorcommerce', name: ''); tt_model = Integration::Contractorcommerce::V1::Base.new(client_api_integration)

        # tt_model = Integration::Contractorcommerce::V1.new()
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          self.client_api_integration = client_api_integration
        end

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'five9', name: '')
                                    end

          @client = @client_api_integration.client
        end

        # validate the access_token & refresh if necessary
        # tt_model.valid_credentials?
        def valid_credentials?
          @client_api_integration.webhook_api_key.present?
        end

        private
      end
    end
  end
end
