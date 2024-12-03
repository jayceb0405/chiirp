# frozen_string_literal: true

# app/presenters/integrations/slack/presenter.rb
module Integrations
  module Slack
    # variables required by Slack integration views
    class Presenter
      attr_reader :client, :user_api_integration

      def initialize(args = {})
        self.user_api_integration = args.dig(:user_api_integration)
      end

      def connection_valid?
        @user_api_integration.token.present?
      end

      def user_api_integration=(user_api_integration)
        @user_api_integration = case user_api_integration
                                when UserApiIntegration
                                  user_api_integration
                                when Integer
                                  UserApiIntegration.find_by(id: user_api_integration)
                                else
                                  UserApiIntegration.new
                                end

        @client = @user_api_integration.user.client
      end
    end
  end
end
