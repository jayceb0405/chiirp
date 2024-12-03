# frozen_string_literal: true

# app/controllers/integrations/housecall/api_keys_controller.rb
module Integrations
  module Housecall
    class ApiKeysController < Housecall::IntegrationsController
      # (DELETE) disconnect Housecall Pro integration
      # /integrations/housecall/api_key
      # integrations_housecall_api_key_path
      # integrations_housecall_api_key_url
      def destroy
        api_key = params.dig(:api_key).to_bool

        if api_key
          hcp_client = Integrations::HousecallPro::Base.new(@client_api_integration.credentials)
          hcp_client.revoke_access_token

          JsonLog.info 'Integrations::Housecall::ApiKeysController.destroy', { hcp_client: }

          if hcp_client.success?
            @client_api_integration.update(credentials: {
                                             access_token:            '',
                                             access_token_expires_at: 0,
                                             refresh_token:           ''
                                           })
          end
        end

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_housecall_url}'" }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (GET) show api_key edit screen
      # /integrations/housecall/api_key/edit
      # edit_integrations_housecall_api_key_path
      # edit_integrations_housecall_api_key_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[api_key_edit] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PATCH/PUT) update api_key
      # /integrations/housecall/api_key
      # integrations_housecall_api_key_path
      # integrations_housecall_api_key_url
      def update
        url = Integrations::HousecallPro::Base.new.request_authentication_url

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_housecall_path}'" }
          format.html { redirect_to url, allow_other_host: true }
        end
      end
    end
  end
end
