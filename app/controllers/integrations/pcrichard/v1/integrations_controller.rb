# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/integrations_controller.rb
module Integrations
  module Pcrichard
    module V1
      class IntegrationsController < ApplicationController
        # rubocop:disable Rails/LexicallyScopedActionFilter
        skip_before_action :verify_authenticity_token, only: %i[new]
        before_action :authenticate_user!, except: %i[new]
        before_action :authorize_user!, except: %i[new]
        before_action :client_api_integration, except: %i[new]
        before_action :client_api_integration_new, only: %i[new]
        # rubocop:enable Rails/LexicallyScopedActionFilter

        # (GET) show the main PC Richard integration screen
        # /integrations/pcrichard/v1
        # integrations_pcrichard_v1_path
        # integrations_pcrichard_v1_url
        def show
          respond_to do |format|
            format.js { render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/pcrichard/v1/show' }
          end
        end

        private

        def authorize_user!
          super

          return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('pcrichard')

          sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access PC Richard Integrations. Please contact your account admin.', '', { persistent: 'OK' })

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client_api_integration
          return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'pcrichard', name: ''))

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client_api_integration_new
          return if (@client_api_integration = ClientApiIntegration.find_by(target: 'pcrichard', name: '', api_key: params.dig(:api_key)))

          render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return false
        end
      end
    end
  end
end
