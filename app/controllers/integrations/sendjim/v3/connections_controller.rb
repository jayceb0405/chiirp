# frozen_string_literal: true

# app/controllers/integrations/sendjim/v3/connections_controller.rb
module Integrations
  module Sendjim
    module V3
      # Support for all general SendJim integration endpoints used with Chiirp
      class ConnectionsController < Sendjim::V3::IntegrationsController
        # (POST) redirect from authorize request to SendJim auth endpoint
        # /integrations/sendjim/v3/auth
        # integrations_sendjim_v3_auth_path
        # integrations_sendjim_v3_auth_url
        def authorize
          redirect_to "https://members.sendjim.com/OAuth/Account?clientKey=#{Rails.application.credentials[:sendjim][:chiirp][:client_key]}&callbackUrl=#{integrations_sendjim_v3_callback_url}", allow_other_host: true
        end

        # (GET) receive callback from SendJim authorization
        # /integrations/sendjim/v3/callback
        # integrations_sendjim_v3_callback_path
        # integrations_sendjim_v3_callback_url
        def callback
          sanitized_params = params.permit(:requestToken, :expires)

          if sanitized_params.dig(:requestToken).to_s.present?
            sj_client = Integrations::SendJim::V3::Sendjim.new('')
            sj_client.request_token(sanitized_params[:requestToken])

            if sj_client.success?
              @client_api_integration.update(token: sj_client.result)
            else
              sweetalert_error('Invalid Token!', "Your SendJim login was unsuccessful. Please contact #{I18n.t('tenant.name')} support. (#{__LINE__})", '', { persistent: 'OK' })
            end
          else
            sweetalert_error('Invalid Token!', "Your SendJim login was unsuccessful. Please contact #{I18n.t('tenant.name')} support. (#{__LINE__})", '', { persistent: 'OK' })
          end

          render 'integrations/sendjim/v3/show'
        end

        # (DELETE) delete a SendJim connection
        # /integrations/sendjim/v3/connection
        # integrations_sendjim_v3_connection_path
        # integrations_sendjim_v3_connection_url
        def destroy
          @client_api_integration.update(token: '')

          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[connections_edit] }
        end

        # (GET) SendJim integration configuration screen
        # /integrations/sendjim/v3/connection/edit
        # edit_integrations_sendjim_v3_connection_path
        # edit_integrations_sendjim_v3_connection_url
        def edit
          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[connections_edit] }
        end
      end
    end
  end
end
