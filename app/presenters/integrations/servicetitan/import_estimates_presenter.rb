# frozen_string_literal: true

# app/presenters/integrations/servicetitan/import_estimates_presenter.rb
module Integrations
  module Servicetitan
    class ImportEstimatesPresenter
      attr_accessor :event
      attr_reader   :api_key, :client, :client_api_integration

      # Integrations::Servicetitan::ImportEstimatesPresenter.new()
      # client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration)
        self.client_api_integration = client_api_integration
      end

      def campaigns_allowed?
        @client.campaigns_count.positive?
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new
                                  end
        @api_key                = @client_api_integration.api_key
        @client                 = @client_api_integration.client
        @estimates_count        = nil

        @st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
        @st_model  = Integration::Servicetitan::V2::Base.new(@client_api_integration)
      end

      def estimates_count(current_user)
        @estimates_count ||= @st_model.import_estimates_remaining_count(current_user.id)
      end

      def groups_allowed?
        @client.groups_count.positive?
      end

      def options_for_status
        [
          %w[Open open],
          %w[Sold sold],
          %w[Dismissed dismissed]
        ]
      end

      def stages_allowed?
        @client.stages_count.positive?
      end
    end
  end
end
