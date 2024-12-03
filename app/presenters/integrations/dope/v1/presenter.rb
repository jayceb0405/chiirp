# frozen_string_literal: true

# app/presenters/integrations/dope/v1/presenter.rb
module Integrations
  module Dope
    module V1
      # variables required by Dope views
      class Presenter
        attr_reader :client_api_integration
        attr_writer :automation

        def initialize(client_api_integration:)
          self.client_api_integration = client_api_integration
        end

        def automation_id
          @automation.dig(:id).to_s
        end

        def automation_name
          @automation.dig(:name).to_s
        end

        def automation_status
          @automation.dig(:status).to_s
        end

        def automation_tag_id
          @client_api_integration.automations.map(&:symbolize_keys).find { |automation| automation.dig(:id) == self.automation_id }&.dig(:tag_id).to_i
        end

        def automation_type
          @automation.dig(:type).to_s
        end

        def automations
          @automations ||= dp_client.automations
        end

        def client
          @client ||= @client_api_integration.client
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

          @automation  = {}
          @automations = nil
          @client      = nil
          @dp_client   = nil
        end

        def dp_client
          @dp_client ||= Integrations::Doper::V1::Dope.new(@client_api_integration.api_key)
        end
      end
    end
  end
end
