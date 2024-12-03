# frozen_string_literal: true

# app/controllers/integrations/jobber/integrations_controller.rb
module Integrations
  module Jobber
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[auth_code endpoint]
      before_action :authenticate_user!, except: %i[auth_code endpoint]
      before_action :authorize_user!, except: %i[auth_code endpoint]
      before_action :client_api_integration, except: %i[auth_code endpoint]
      before_action :validate_webhook_source, only: %i[endpoint]

      # (GET) receive auth token from Jobber and convert into access_token & refresh_token
      # /integrations/jobber/authcode
      # integrations_jobber_auth_code_path
      # integrations_jobber_auth_code_url
      def auth_code
        complete_oauth2_connection_flow

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_jobber_path}'" and return false }
          format.html { redirect_to integrations_jobber_path and return false }
        end
      end

      # (POST) Jobber webhook endpoint
      # /integrations/jobber/endpoint
      # integrations_jobber_endpoint_path
      # integrations_jobber_endpoint_url
      def endpoint
        sanitized_params = params_endpoint
        client_api_integration_count = 0

        ClientApiIntegration.joins(:client).where(target: 'jobber', name: '').where('client_api_integrations.data @> ?', { account: { id: sanitized_params.dig(:webHookEvent, :accountId) } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
          next if Integration::Jobber::Base.new(client_api_integration).current_version.blank?

          Rails.logger.info "client_api_integration.id: #{client_api_integration.id.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          client_api_integration_count += 1
          data = {
            client_api_integration_id: client_api_integration.id,
            account_id:                sanitized_params.dig(:webHookEvent, :accountId),
            item_id:                   sanitized_params.dig(:webHookEvent, :itemId),
            process_events:            true,
            raw_params:                params.except(:integration),
            topic:                     sanitized_params.dig(:webHookEvent, :topic)
          }
          "Integration::Jobber::V#{Integration::Jobber::Base.new(client_api_integration).current_version}::Event".constantize.new(data).delay(
            run_at:              Time.current,
            priority:            DelayedJob.job_priority('jobber_process_event'),
            queue:               DelayedJob.job_queue('jobber_process_event'),
            user_id:             0,
            contact_id:          0,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'jobber_process_event',
            data:
          ).process
        end

        if client_api_integration_count.positive?
          render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
        else
          render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
        end
      end

      # (GET) show Jobber integration overview screen
      # /integrations/jobber
      # integrations_jobber_path
      # integrations_jobber_url
      def show
        client_api_integration = current_user.client.client_api_integrations.find_by(target: 'jobber', name: '')
        path                   = send(:"integrations_jobber_v#{Integration::Jobber::Base.new(client_api_integration).current_version}_path")

        respond_to do |format|
          format.js { render js: "window.location = '#{path}'" and return false }
          format.html { redirect_to path and return false }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('jobber')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Jobber Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'jobber', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def complete_oauth2_connection_flow
        # TODO: can probably remove this JsonLog
        JsonLog.info 'Integrations::Jobber::IntegrationsController.complete_oauth2_connection_flow', { params: }

        if oauth2_connection_completed_when_started_from_chiirp || oauth2_connection_completed_when_started_from_jobber
          sweetalert_success('Success!', 'Connection to Jobber was completed successfully.', '', { persistent: 'OK' })
        else
          disconnect_incomplete_connection
          sweetalert_error('Unathorized Access!', 'Unable to locate an account with Jobber credentials received. Please contact your account admin.', '', { persistent: 'OK' })
        end
      end

      def disconnect_incomplete_connection
        sanitized_params = params_auth_code
        JsonLog.info 'Integrations::Jobber::IntegrationsController.disconnect_incomplete_account', { sanitized_params: }

        jb_client = "Integrations::JobBer::V#{Integration::Jobber::Base::CURRENT_VERSION}::Base".constantize.new({})
        jb_client.request_access_token(sanitized_params.dig(:code))
        JsonLog.info 'Integrations::Jobber::IntegrationsController.disconnect_incomplete_account', { jb_client_01: jb_client }

        return unless jb_client.success?

        jb_client = "Integrations::JobBer::V#{Integration::Jobber::Base::CURRENT_VERSION}::Base".constantize.new(jb_client.result)
        jb_client.disconnect_account
        JsonLog.info 'Integrations::Jobber::IntegrationsController.disconnect_incomplete_account', { jb_client_02: jb_client }
      end

      def oauth2_connection_completed_when_started_from_chiirp
        sanitized_params = params_auth_code

        sanitized_params.dig(:state).present? && (@client_api_integration = ClientApiIntegration.find_by('data @> ?', { auth_code: sanitized_params[:state] }.to_json)) &&
          sanitized_params.dig(:code).present? && "Integration::Jobber::V#{Integration::Jobber::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
          "Integration::Jobber::V#{Integration::Jobber::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_account
      end

      def oauth2_connection_completed_when_started_from_jobber
        sanitized_params = params_auth_code

        sanitized_params.dig(:state).blank? && (@client_api_integration = current_user&.client&.client_api_integrations&.find_or_create_by(target: 'jobber', name: '')) &&
          sanitized_params.dig(:code).present? && "Integration::Jobber::V#{Integration::Jobber::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_credentials(sanitized_params[:code]) &&
          "Integration::Jobber::V#{Integration::Jobber::Base::CURRENT_VERSION}::Base".constantize.new(@client_api_integration).update_account
      end

      def params_endpoint
        params.require(:data).permit(webHookEvent: %i[accountId appId itemId occuredAt topic])
      end

      def params_auth_code
        params.permit(:code, :state)
      end

      def validate_webhook_source
        calculated_hmac = Base64.strict_encode64(
          OpenSSL::HMAC.digest(
            'sha256',
            Rails.configuration.x.jobber.client_secret || '',
            ActiveSupport::JSON.encode({ data: params.permit(:data).dig(:data) })
          )
        )

        ActiveSupport::SecurityUtils.secure_compare(
          calculated_hmac,
          request.headers['X-Jobber-Hmac-SHA256']
        )
      rescue StandardError
        render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return false
      end
    end
  end
end
