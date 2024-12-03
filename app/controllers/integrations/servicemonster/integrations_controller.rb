# frozen_string_literal: true

# app/controllers/integrations/servicemonster/integrations_controller.rb
module Integrations
  module Servicemonster
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[auth_code webhook]
      before_action :authenticate_user!, except: %i[auth_code webhook]
      before_action :authorize_user!, except: %i[auth_code webhook]
      before_action :client, except: %i[auth_code webhook]
      before_action :client_api_integration, except: %i[auth_code webhook]

      # (GET) callback from ServiceMonster with authorization code
      # /integrations/service_monster/endpoint/authcode
      # /integrations/servicemonster/endpoint/authcode
      # integrations_servicemonster_auth_code_path
      # integrations_servicemonster_auth_code_url
      # /integrations/servicemonster/endpoint/authcode/:sub_integration
      # integrations_servicemonster_auth_code_path(:sub_integration)
      # integrations_servicemonster_auth_code_url(:sub_integration)
      def auth_code
        update_servicemonster_company_and_credentials

        respond_to do |format|
          if @client_api_integration
            format.json { render json: { status: 200, message: 'success' } }
            format.html { render 'integrations/servicemonster/show' }
          else
            format.html { redirect_to integrations_servicemonster_path }
          end
        end
      end

      # (POST) webhook from ServiceMonster
      # /integrations/servicemonster/endpoint/webhook/:webhook_id
      # integrations_servicemonster_endpoint_path(:webhook_id)
      # integrations_servicemonster_endpoint_url(:webhook_id)
      def webhook
        if (client_api_integrations = ClientApiIntegration.where(target: 'servicemonster', name: '').where('data @> ?', { company: { companyID: params.dig(:companyID).to_s } }.to_json)).present?
          respond_to do |format|
            format.json { render json: { status: 200, message: 'Success' } }
            format.html { render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok }
          end

          data = {
            client_api_integration_ids: client_api_integrations.pluck(:id),
            company_id:                 params.dig(:companyID).to_s,
            params:                     params.to_unsafe_hash.deep_symbolize_keys,
            process_events:             true,
            raw_params:                 params.except(:integration),
            webhook_id:                 params.dig(:webhook_id).to_s
          }
          # ServiceMonster sometimes sends updates before or simultaneous to the account created causing duplicate Contacts
          # Delay all webhooks (except account created) by 15 seconds
          Integration::Servicemonster.delay(
            run_at:              Integration::Servicemonster.webhook_by_id(client_api_integrations.first.webhooks, params.dig(:webhook_id).to_s).keys.first == :account_OnCreated ? Time.current : 15.seconds.from_now,
            priority:            DelayedJob.job_priority('servicemonster_process_job'),
            queue:               DelayedJob.job_queue('servicemonster_process_job'),
            user_id:             0,
            contact_id:          0,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'servicemonster_process_job',
            data:
          ).event_process(data)
        else
          respond_to do |format|
            format.json { render json: { status: 404, message: 'Company not found.' } and return }
            format.html { render plain: 'Company not found.', content_type: 'text/plain', layout: false, status: :not_found and return }
          end
        end
      end

      # (GET) show ServiceMonster integration
      # /integrations/servicemonster
      # integrations_servicemonster_path
      # integrations_servicemonster_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/servicemonster/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/servicemonster/#{params[:card]}/index" : '' } }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('servicemonster')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Service Monster Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client
        # set up Client object
        @client = current_user.client
      end

      def client_api_integration
        # set up ClientApiIntegration object
        return if (@client_api_integration = @client.client_api_integrations.find_or_create_by(target: 'servicemonster', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def update_servicemonster_company_and_credentials
        sanitized_params = params.permit(:requestID, :sub_integration)
        request_id       = sanitized_params.dig(:requestID).to_s.strip
        sub_integration  = sanitized_params.dig(:sub_integration).to_s.strip

        sm_client = Integrations::ServiceMonster.new({ sub_integration: })
        sm_client.authenticate_request_id(request_id)

        return unless sm_client.success? && current_user

        client
        client_api_integration

        credentials = sm_client.credentials(request_id).merge({ sub_integration: })

        return unless sm_client.success?

        sm_client = Integrations::ServiceMonster.new(credentials)
        @client_api_integration.update(credentials:, company: sm_client.company)
      end
    end
  end
end
