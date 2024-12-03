# frozen_string_literal: true

# app/presenters/integrations/fieldpulse/v1/presenter.rb
module Integrations
  module Fieldpulse
    module V1
      class Presenter < BasePresenter
        attr_reader :event, :event_name, :events, :webhook, :webhooks, :webhook_id

        # Integrations::Fieldpulse::V1::Presenter.new()
        #   (req) client_api_integration: (ClientApiIntegration) or (Integer)

        def client_api_integration=(client_api_integration)
          super

          @fp_model = Integration::Fieldpulse::V1::Base.new(@client_api_integration)
        end

        def connection_good?
          @fp_model.valid_credentials?
        end
      end
    end
  end
end
