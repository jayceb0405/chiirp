# frozen_string_literal: true

# app/models/integration/thumbtack/base.rb
module Integration
  module Thumbtack
    class Base
      CURRENT_VERSION = '2'

      # tt_model = Integration::Thumbtack::Base.new()
      #   (req) client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration = nil)
        reset_attributes
        @client_api_integration = client_api_integration
        refresh_client
      end

      def current_version
        @client_api_integration&.credentials&.dig('version').presence || CURRENT_VERSION
      end

      # validate the access_token & refresh if necessary
      # tt_model.valid_credentials?
      def valid_credentials?
        "Integration::Thumbtack::V#{current_version}::Base".constantize.new(@client_api_integration).valid_credentials?
      end

      private

      def client_api_integration=(client_api_integration)
        case client_api_integration
        when ClientApiIntegration
          client_api_integration
        when Integer
          ClientApiIntegration.find_by(id: client_api_integration)
        else
          ClientApiIntegration.new(target: 'thumbtack', name: '')
        end
      end

      def refresh_client
        @tt_client = "Integrations::ThumbTack::V#{current_version}::Base".constantize.new(@client_api_integration.credentials)
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
