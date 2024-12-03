# frozen_string_literal: true

# app/controllers/integrations/sendgrid/v1/api_keys_controller.rb
module Integrations
  module Sendgrid
    module V1
      class ApiKeysController < Sendgrid::V1::IntegrationsController
        # (DELETE) delete the entire SendGrid integration
        # /integrations/sendgrid/v1/api_key
        # integrations_sendgrid_v1_api_key_path
        # integrations_sendgrid_v1_api_key_url
        def destroy
          @client_api_integration.destroy

          render js: "window.location = '#{integrations_sendgrid_v1_path}'"
        end

        # (GET) show api_key edit screen
        # /integrations/sendgrid/v1/api_key/edit
        # edit_integrations_sendgrid_v1_api_key_path
        # edit_integrations_sendgrid_v1_api_key_url
        def edit
          render partial: 'integrations/sendgrid/v1/js/show', locals: { cards: %w[api_key_edit] }
        end

        # (PATCH/PUT) update api_key
        # /integrations/sendgrid/v1/api_key
        # integrations_sendgrid_v1_api_key_path
        # integrations_sendgrid_v1_api_key_url
        def update
          @client_api_integration.update(api_key: params.require(:client_api_integration).permit(:api_key).dig(:api_key).to_s)

          render partial: 'integrations/sendgrid/v1/js/show', locals: { cards: %w[api_key_edit] }
        end
      end
    end
  end
end
