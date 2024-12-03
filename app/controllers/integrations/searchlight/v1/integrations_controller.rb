# frozen_string_literal: true

# app/controllers/integrations/searchlight/v1/integrations_controller.rb
module Integrations
  module Searchlight
    module V1
      class IntegrationsController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_user!
        before_action :authorize_user!
        before_action :client_api_integration
        # (GET) show the main SearchLight integration screen
        # /integrations/searchlight/v1
        # integrations_searchlight_v1_path
        # integrations_searchlight_v1_url
        def show
          respond_to do |format|
            format.js { render partial: 'integrations/searchlight/v1/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/searchlight/v1/show' }
          end
        end

        private

        def authorize_user!
          super

          return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('searchlight')

          sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access SearchLight Integrations. Please contact your account admin.', '', { persistent: 'OK' })

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client_api_integration
          return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'searchlight', name: ''))

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end
      end
    end
  end
end
