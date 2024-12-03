# frozen_string_literal: true

# app/controllers/integrations/thumbtack/integrations_controller.rb
module Integrations
  module Thumbtack
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :client
      before_action :client_api_integration

      CURRENT_VERSION = '2'

      # (GET) receive auth token from Thumbtack, convert into access_token & refresh_token
      # /integrations/thumbtack/authcode
      # integrations_thumbtack_auth_code_path
      # integrations_thumbtack_auth_code_url
      def auth_code
        complete_oauth2_connection_flow

        redirect_to integrations_thumbtack_integration_path
      end
      # example params:
      # {
      #   code:  'B87feB7cdrkV7AAvaYP3gw',
      #   scope: 'messages',
      #   state: 'dc156f9c-e4ec-4102-aa3f-a125552c8399'
      # }

      # (GET) show Thumbtack main integration screen
      # /integrations/thumbtack/integration
      # integrations_thumbtack_integration_path
      # integrations_thumbtack_integration_url
      def show
        ensure_auth_code_exists
        @version = @client_api_integration&.data&.dig('credentials', 'version') || CURRENT_VERSION
      end

      private

      def authorize_user!
        super

        return true if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('thumbtack')

        raise ExceptionHandlers::UserNotAuthorized.new('Thumbtack Integrations', root_path)
      end

      def client
        @client = current_user.client
      end

      def client_api_integration
        return true if (@client_api_integration = @client.client_api_integrations.find_or_create_by(target: 'thumbtack', name: ''))

        raise ExceptionHandlers::UserNotAuthorized.new('Thumbtack Integrations', root_path)
      end

      def complete_oauth2_connection_flow
        if oauth2_connection_completed_when_started_from_chiirp
          sweetalert_success('Success!', 'Connection to Thumbtack was completed successfully.', '', { persistent: 'OK' })
        else
          disconnect_incomplete_connection
          sweetalert_error('Unathorized Access!', 'Unable to locate an account with Thumbtack credentials received. Please contact your account admin.', '', { persistent: 'OK' })
        end
      end

      def disconnect_incomplete_connection
        sanitized_params = params_auth_code
        Rails.logger.info "Integrations::Thumbtack::IntegrationsController.disconnect_incomplete_account: #{{ sanitized_params: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        tt_client = Integrations::ThumbTack::V2::Base.new(@client_api_integration.credentials)
        Rails.logger.info "Integrations::Thumbtack::IntegrationsController.disconnect_incomplete_account: #{{ tt_client_01: tt_client }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        tt_client.disconnect_account(@client_api_integration.account.dig(:business_pk)) if @client_api_integration&.account&.dig(:business_pk).present?
        Rails.logger.info "Integrations::Thumbtack::IntegrationsController.disconnect_incomplete_account: #{{ tt_client_02: tt_client }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      end

      def ensure_auth_code_exists
        return true if @client_api_integration&.auth_code.present?

        @client_api_integration.update(auth_code: SecureRandom.uuid)
      end

      def oauth2_connection_completed_when_started_from_chiirp
        sanitized_params = params_auth_code

        return false unless sanitized_params.dig(:scope).present? && sanitized_params.dig(:code).present? && sanitized_params.dig(:state).present? &&
                            (@client_api_integration = ClientApiIntegration.find_by('data @> ?', { auth_code: sanitized_params[:state] }.to_json))

        tt_model = Integration::Thumbtack::V2::Base.new(@client_api_integration)

        tt_model.update_credentials(code: sanitized_params[:code], scope: sanitized_params[:scope]) && tt_model.update_account
      end

      def params_endpoint
        params.require(:data).permit(webHookEvent: %i[accountId appId itemId occuredAt topic])
      end

      def params_auth_code
        params.permit(:code, :scope, :state)
      end
    end
  end
end
# https://staging-pro-api.thumbtack.com/v2/tokens/access?code=B87feB7cdrkV7AAvaYP3gw&grant_type=authorization_code&redirect_uri=https%253A%252F%252Fdev.chiirp.com%252Fintegrations%252Fthumbtack%252Fauthcode&token_type=AUTH_CODE
