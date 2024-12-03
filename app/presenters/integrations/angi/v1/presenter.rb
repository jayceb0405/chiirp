# frozen_string_literal: true

# app/presenters/integrations/angi/v1/events/presenter.rb
module Integrations
  module Angi
    module V1
      class Presenter < BasePresenter
        attr_reader :client, :client_api_integration

        # Integrations::Angi::V1::Presenter.new(user_api_integration: @user_api_integration)
        #   (req) user_api_integration: (UserApiIntegration) or (Integer)

        def initialize(args = {})
          super

          @ag_model = Integration::Angi::V1::Base.new(@client_api_integration)
        end

        def connection_good?
          @ag_model.valid_credentials?
        end

        def event_count
          @ag_model.event_count
        end
      end
    end
  end
end
