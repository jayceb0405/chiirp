# frozen_string_literal: true

# app/presenters/integrations/email/v1/presenter.rb
module Integrations
  module Email
    module V1
      class Presenter < BasePresenter
        attr_reader :domain, :ips, :api_key, :username, :domain_validated

        # Integrations::Email::V1::Presenter.new(client_api_integration: @client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration) or (Integer)

        def client_api_integration=(client_api_integration)
          super

          @username         = client_api_integration.username
          @domain           = client_api_integration.domain
          @ips              = client_api_integration.ips
          @api_key          = client_api_integration.api_key
          @domain_validated = client_api_integration.domain_validated
          @em_model         = Integration::Email::V1::Base.new(client_api_integration)
        end

        def connected?
          @connected ||= @em_model.connected?
        end

        # verify that CardX credentials are valid
        # presenter.valid_credentials?
        def valid_credentials?
          @valid_credentials ||= @em_model.valid_credentials?
        end
      end
    end
  end
end
