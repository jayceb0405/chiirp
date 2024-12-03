# frozen_string_literal: true

# app/controllers/integrations/successware/integrations_controller.rb
module Integrations
  module Successware
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[confirm endpoint register]
      before_action :authenticate_user!, except: %i[confirm endpoint register]
      before_action :authorize_user!, except: %i[confirm endpoint register]
      before_action :client_api_integration, except: %i[confirm endpoint register]

      CURRENT_VERSION = '202311'

      # (GET) receive api_key from Successware to confirm Client
      # /integrations/successware/confirm
      # integrations_successware_confirm_path
      # integrations_successware_confirm_url
      def confirm
        response = {
          confirmAccountResponse: {
            confirmed:       false,
            message:         'Your account can not be confirmed.',
            'redirect-link': integrations_successware_url
          }
        }

        if valid_confirmation?
          response[:confirmAccountResponse][:confirmed] = true
          response[:confirmAccountResponse][:message]   = 'Your account has been confirmed.'

          render json: response.to_json, content_type: 'application/json', layout: false, status: :ok
        else
          render json: response.to_json, content_type: 'application/json', layout: false, status: :not_found
        end
      end
      # example payload
      # {
      #   "confirmAccount": {
      #     "credential1": {
      #       "label": "ApiKey",
      #       "text": "jdoe@joescompany.com"
      #     },
      #     "credential2": {
      #       "label": "Secret",
      #       "text": "yc2KsreY1TtD"
      #     },
      #     "credential3": {
      #       "label": "Other",
      #       "text": "yc2KsreY1TtD"
      #     }
      #   }
      # }
      # appropriate response
      # {
      #   "confirmAccountResponse": {
      #     "confirmed": "true",
      #     "message": "Your account has been confirmed.",
      #     "redirect-link": "https:/members.solution.com/moresucceswareinfo"
      #   }
      # }

      # (POST) Successware webhook endpoint
      # /integrations/successware/endpoint
      # integrations_successware_endpoint_path
      # integrations_successware_endpoint_url
      def endpoint
        sanitized_params = params_endpoint
        client_api_integration_count = 0

        ClientApiIntegration.joins(:client).where(target: 'successware', name: '').where('clients.data @> ?', { active: true }.to_json).where('client_api_integrations.data @> ?', { credentials: { master_id: sanitized_params.dig(:masterID) } }.to_json).where('client_api_integrations.data @> ?', { credentials: { company_no: sanitized_params.dig(:companyNo) } }.to_json).find_each do |client_api_integration|
          client_api_integration_count += 1
          data = {
            event:          sanitized_params.dig(:addInfo, :progress),
            job_id:         sanitized_params.dig(:addInfo, :jobID),
            job_no:         sanitized_params.dig(:addInfo, :jobNo),
            process_events: true,
            raw_params:     params.except(:integration),
            tenant_id:      sanitized_params.dig(:companyNo),
            source_id:      sanitized_params.dig(:sourceId)
          }
          "Integration::Successware::V#{client_api_integration.data.dig('credentials', 'version')}::Base".constantize.new(client_api_integration:).delay(
            run_at:              Time.current,
            priority:            DelayedJob.job_priority('successware_process_event'),
            queue:               DelayedJob.job_queue('successware_process_event'),
            user_id:             0,
            contact_id:          0,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'successware_process_event',
            data:
          ).process_webhook(data)
        end

        if client_api_integration_count.positive?
          render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
        else
          render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
        end
      end
      # example webhook payload
      # {
      #   "created": "2023-12-09T18:50:48.000000001",
      #   "masterID": "60074",
      #   "companyNo": "1001",
      #   "sourceType": "call",
      #   "sourceID": "532631892961464138",
      #   "processed": "2023-12-09T18:50:48.000000001",
      #   "addInfo": {
      #     "jobNo": "201147",
      #     "jobID": "532631892961357642",
      #     "progress": "Scheduled",
      #     "jobDept": null,
      #     "msgName": null
      #   }
      # }

      # (GET) receive registration from Successware and connect to Client
      # /integrations/successware/register
      # integrations_successware_register_path
      # integrations_successware_register_url
      def register
        response = {
          addOnTenantRegistrationResponse: {
            successful:      false,
            message:         'Connection unsuccessful',
            'redirect-link': integrations_successware_url
          }
        }

        if valid_registration?
          response[:addOnTenantRegistrationResponse][:successful] = true
          response[:addOnTenantRegistrationResponse][:message]    = 'Connection successful'

          render json: response.to_json, content_type: 'application/json', layout: false, status: :ok
        else
          render json: response.to_json, content_type: 'application/json', layout: false, status: :not_found
        end
      end
      # example payload
      # {
      #   "addOnTenantRegistration": {
      #     "credential1": {
      #       "label": "ApiKey",
      #       "text": "jdoe@joescompany.com"
      #     },
      #     "credential2": {
      #       "label": "Secret",
      #       "text": "yc2KsreY1TtD"
      #     },
      #     "credential3": {
      #       "label": "Other",
      #       "text": "yc2KsreY1TtD"
      #     },
      #     "tenantId": "500",
      #     "agentUser": "agentname@500.com",
      #     "agentSecret": "nopM0W3X"
      #   }
      # }
      # appropriate response
      # {
      #   "addOnTenantRegistrationResponse": {
      #     "successful": "true",
      #     "message": "Connection successful",
      #     "redirect-link": "https://members.solution.com/myaccount"
      #   }
      # }

      # (GET) show main Successware integration screen
      # /integrations/successware
      # integrations_successware_path
      # integrations_successware_url
      def show
        client_api_integration = current_user.client.client_api_integrations.find_by(target: 'successware', name: '')

        path = if (version = client_api_integration&.data&.dig('credentials', 'version')).present?
                 send(:"integrations_successware_v#{version}_path")
               else
                 send(:"integrations_successware_v#{CURRENT_VERSION}_path")
               end

        respond_to do |format|
          format.js { render js: "window.location = '#{path}'" and return false }
          format.html { redirect_to path and return false }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('successware')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Successware Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'successware', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def params_auth_code
        params.permit(:code, :state)
      end

      def params_confirmation
        if params.include?(:confirmAccount)
          params.require(:confirmAccount).permit(credential1: %i[label text], credential2: %i[label text], credential3: %i[label text])
        else
          {}
        end
      end

      def params_endpoint
        params.permit(:created_at, :masterID, :companyNo, :sourceType, :sourceID, :processed, addInfo: %i[jobNo jobID progress jobDept msgName])
      end

      def params_registration
        if params.include?(:addOnTenantRegistration)
          params.require(:addOnTenantRegistration).permit(:tenantId, :agentUser, :agentSecret, credential1: %i[label text], credential2: %i[label text], credential3: %i[label text])
        else
          {}
        end
      end

      def parse_api_key_and_secret(sanitized_params)
        credentials = [sanitized_params.dig(:credential1), sanitized_params.dig(:credential2), sanitized_params.dig(:credential3)]
        [credentials.find { |c| c&.dig(:label)&.casecmp?('apikey') }&.dig(:text), credentials.find { |c| c&.dig(:label)&.casecmp?('secret') }&.dig(:text)]
      end

      def valid_confirmation?
        api_key, secret = parse_api_key_and_secret(params_confirmation)

        return false if api_key.blank? || secret.blank?

        ClientApiIntegration.find_by(target: 'successware', name: '', api_key:).present? && Crypt.decrypt(secret) == api_key
      end

      def valid_registration?
        sanitized_params = params_registration
        api_key, secret  = parse_api_key_and_secret(sanitized_params)

        return false if api_key.blank? || secret.blank?
        return false unless (client_api_integration = ClientApiIntegration.find_by(target: 'successware', name: '', api_key:)) && Crypt.decrypt(secret) == api_key

        client_api_integration.credentials[:tenant_id] = sanitized_params.dig(:tenantId).to_s
        client_api_integration.credentials[:user_name] = sanitized_params.dig(:agentUser).to_s
        client_api_integration.credentials[:password]  = sanitized_params.dig(:agentSecret).to_s
        client_api_integration.credentials[:version]   = CURRENT_VERSION
        client_api_integration.save

        true
      end
    end
  end
end
