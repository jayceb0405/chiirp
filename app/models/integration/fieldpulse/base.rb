# frozen_string_literal: true

# app/models/integration/fieldpulse/v1/base.rb
module Integration
  module Fieldpulse
    class Base
      attr_reader :error, :message, :result, :success
      alias success? success

      CURRENT_VERSION = '1'

      # fp_model = Integration::Fieldpulse::V1::Base.new()
      #   (req) client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration = nil)
        self.client_api_integration = client_api_integration
      end

      def current_version
        @client_api_integration&.credentials&.dig('version').presence || CURRENT_VERSION
      end

      # validate the access_token & refresh if necessary
      # fp_model.valid_credentials?
      def valid_credentials?
        "Integration::Fieldpulse::V#{current_version}::Base".constantize.new(@client_api_integration).valid_credentials?
      end

      private

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new(target: 'fieldpulse', name: '')
                                  end

        @client    = @client_api_integration.client
        @fp_client = "Integrations::FieldPulse::V#{current_version}::Base".constantize.new(@client_api_integration.api_key)
      end
    end
  end
end
