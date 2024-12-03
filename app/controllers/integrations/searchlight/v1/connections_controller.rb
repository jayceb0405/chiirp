# frozen_string_literal: true

# app/controllers/integrations/searchlight/v1/connections_controller.rb
module Integrations
  module Searchlight
    module V1
      class ConnectionsController < Searchlight::V1::IntegrationsController
        # (GET) show the SearchLight connections screen
        # /integrations/searchlight/v1/connections/edit
        # edit_integrations_searchlight_v1_connection_path
        # edit_integrations_searchlight_v1_connection_url
        def edit
          render partial: 'integrations/searchlight/v1/js/show', locals: { cards: %w[connections_edit] }
        end

        # (PATCH/PUT) save the SearchLight on/off setting
        # /integrations/searchlight/v1/connections
        # integrations_searchlight_v1_connection_path
        # integrations_searchlight_v1_connection_url
        def update
          @client_api_integration.update(params_active)

          if @client_api_integration.active
            sl_model = Integration::Searchlight::V1::Base.new(@client_api_integration.client)
            sl_model.update_searchlight_key
          else
            @client_api_integration.update(api_key: '')
          end

          render partial: 'integrations/searchlight/v1/js/show', locals: { cards: %w[connections_edit] }
        end

        private

        def params_active
          sanitized_params = params.permit(:active)

          sanitized_params[:active] = sanitized_params.dig(:active).to_bool

          sanitized_params
        end
      end
    end
  end
end
