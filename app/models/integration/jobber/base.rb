# frozen_string_literal: true

# app/models/integration/jobber/v20220915/base.rb
module Integration
  module Jobber
    class Base
      CURRENT_VERSION = '20231115'

      # jb_model = Integration::Jobber::V20231115::Base.new()
      #   (req) credentials: (Hash)
      def initialize(client_api_integration = nil)
        self.client_api_integration = client_api_integration
      end

      def current_version
        @client_api_integration&.credentials&.dig('version').presence || CURRENT_VERSION
      end

      # validate the access_token & refresh if necessary
      # jb_model.valid_credentials?
      def valid_credentials?
        "Integration::Jobber::V#{current_version}::Base".constantize.new(@client_api_integration).valid_credentials?
      end

      private

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new(target: 'jobber', name: '')
                                  end

        @client    = @client_api_integration.client
        @jb_client = "Integrations::JobBer::V#{current_version}::Base".constantize.new(@client_api_integration.credentials)
      end
    end
  end
end
