# frozen_string_literal: true

# app/presenters/integrations/five9/v12/connection/presenter.rb
module Integrations
  module Five9
    module V12
      module Connection
        class Presenter < BasePresenter
          attr_reader :client, :client_api_integration

          # Integrations::Five9::V1::Presenter.new(user_api_integration: @user_api_integration)
          #   (req) user_api_integration: (UserApiIntegration) or (Integer)

          def initialize(args = {})
            super

            @f9_model = Integration::Five9::Base.new(@client_api_integration)
          end

          def valid_credentials?
            @f9_model.call(:valid_credentials?)
          end
        end
      end
    end
  end
end
