# frozen_string_literal: true

# app/presenters/integrations/fieldroutes/v1/events/presenter.rb
module Integrations
  module Fieldroutes
    module V1
      class Presenter < BasePresenter
        attr_reader :client, :client_api_integration

        # Integrations::Fieldroutes::V1::Presenter.new(user_api_integration: @user_api_integration)
        #   (req) user_api_integration: (UserApiIntegration) or (Integer)

        def initialize(args = {})
          super

          @fr_model = Integration::Fieldroutes::V1::Base.new(@client_api_integration)
        end

        def connection_good?
          @fr_model.valid_credentials?
        end
      end
    end
  end
end
