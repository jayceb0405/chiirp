# frozen_string_literal: true

# app/controllers/integrations/jobber/v20220915/connections_controller.rb
module Integrations
  module Jobber
    module V20220915
      class ConnectionsController < Jobber::V20220915::IntegrationsController
        # (GET) receive auth token from Jobber and convert into access_token & refresh_token
        # /integrations/jobber/v20220915/endpoint/authcode
        # integrations_jobber_v20220915_auth_code_path
        # integrations_jobber_v20220915_auth_code_url
        def auth_code
          complete_oauth2_connection_flow

          respond_to do |format|
            format.js { render js: "window.location = '#{integrations_jobber_v20220915_path}'" and return false }
            format.html { redirect_to integrations_jobber_v20220915_path and return false }
          end
        end

        # (DELETE) delete a Jobber integration
        # /integrations/jobber/v20220915/connections
        # integrations_jobber_v20220915_connections_path
        # integrations_jobber_v20220915_connections_url
        def destroy
          Integration::Jobber::V20220915::Base.new(@client_api_integration).disconnect_account

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[connections_edit] }
        end

        # (GET) Jobber integration configuration screen
        # /integrations/jobber/v20220915/connections/edit
        # edit_integrations_jobber_v20220915_connections_path
        # edit_integrations_jobber_v20220915_connections_url
        def edit
          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[connections_edit] }
        end

        private

        def complete_oauth2_connection_flow
          # TODO: can probably remove this JsonLog
          JsonLog.info 'Integrations::Jobber::V20220915::ConnectionsController.complete_oauth2_connection_flow', { params: }

          if oauth2_connection_completed_when_started_from_chiirp || oauth2_connection_completed_when_started_from_jobber
            sweetalert_success('Success!', 'Connection to Jobber was completed successfully.', '', { persistent: 'OK' })
          else
            disconnect_incomplete_connection
            sweetalert_error('Unathorized Access!', 'Unable to locate an account with Jobber credentials received. Please contact your account admin.', '', { persistent: 'OK' })
          end
        end

        def disconnect_incomplete_connection
          sanitized_params = params_auth_code
          JsonLog.info 'Integrations::Jobber::V20220915::ConnectionsController.disconnect_incomplete_account', { sanitized_params: }

          jb_client = Integrations::JobBer::V20220915::Base.new({})
          jb_client.request_access_token(sanitized_params.dig(:code))
          JsonLog.info 'Integrations::Jobber::V20220915::ConnectionsController.disconnect_incomplete_account', { jb_client_01: jb_client }

          return unless jb_client.success?

          jb_client = Integrations::JobBer::V20220915::Base.new(jb_client.result)
          jb_client.disconnect_account
          JsonLog.info 'Integrations::Jobber::V20220915::ConnectionsController.disconnect_incomplete_account', { jb_client_02: jb_client }
        end

        def oauth2_connection_completed_when_started_from_chiirp
          sanitized_params = params_auth_code

          sanitized_params.dig(:state).present? && (@client_api_integration = ClientApiIntegration.find_by('data @> ?', { auth_code: sanitized_params[:state] }.to_json)) &&
            sanitized_params.dig(:code).present? && Integration::Jobber::V20220915::Base.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
            Integration::Jobber::V20220915::Base.new(@client_api_integration).update_account
        end

        def oauth2_connection_completed_when_started_from_jobber
          sanitized_params = params_auth_code

          sanitized_params.dig(:state).blank? && (@client_api_integration = current_user&.client&.client_api_integrations&.find_or_create_by(target: 'jobber', name: '')) &&
            sanitized_params.dig(:code).present? && Integration::Jobber::V20220915::Base.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
            Integration::Jobber::V20220915::Base.new(@client_api_integration).update_account
        end

        def params_auth_code
          params.permit(:code, :state)
        end
      end
    end
  end
end
