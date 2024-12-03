# frozen_string_literal: true

# app/controllers/integrations/housecall/integrations_controller.rb
module Integrations
  module Housecall
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[auth_code endpoint]
      before_action :authenticate_user!, except: %i[auth_code endpoint]
      before_action :authorize_user!, except: %i[auth_code endpoint]
      before_action :client, except: %i[auth_code endpoint]
      before_action :client_api_integration, except: %i[auth_code endpoint]

      # (GET) callback from Housecall Pro with authorization code
      # /integrations/housecall/endpoint/authcode
      # integrations_housecall_auth_code_path
      # integrations_housecall_auth_code_url
      def auth_code
        code = params.dig(:code).to_s.strip
        error = params.dig(:error).to_s

        if error == 'access_denied'

          if (@client_api_integration = current_user.client.client_api_integrations.find_or_initialize_by(target: 'housecall', name: ''))
            @client_api_integration.update(
              company:     {},
              credentials: {
                access_token:            '',
                access_token_expires_at: 0,
                refresh_token:           ''
              }
            )
          end
        elsif code.present?
          hcp_client = Integrations::HousecallPro::Base.new
          hcp_client.request_access_token(auth_code: code)

          if hcp_client.success? && (@client_api_integration = current_user.client.client_api_integrations.find_or_initialize_by(target: 'housecall', name: ''))
            @client_api_integration.update(
              credentials: {
                access_token:            hcp_client.result.dig(:access_token).to_s,
                access_token_expires_at: (Time.at(hcp_client.result.dig(:created_at).to_i).utc + hcp_client.result.dig(:expires_in).to_i.seconds).to_i,
                refresh_token:           hcp_client.result.dig(:refresh_token).to_s
              }
            )
            new_hcp_client = Integrations::HousecallPro::Base.new(@client_api_integration.credentials)
            @client_api_integration.update(company: new_hcp_client.company)
          end
        end

        respond_to do |format|
          if @client_api_integration
            format.json { render json: { status: 200, message: 'success' } }
            format.html { render 'integrations/housecall/show' }
          else
            format.html { redirect_to integrations_housecall_path }
          end
        end
      end

      # (POST) receive Housecall Pro webhooks
      # /integrations/housecall/endpoint/webhook
      # integrations_housecall_endpoint_path
      # integrations_housecall_endpoint_url
      def endpoint
        if (@client_api_integration = ClientApiIntegration.where(target: 'housecall', name: '').find_by('data @> ?', { company: { id: params.dig(:company_id).to_s } }.to_json))
          hcp_model  = Integration::Housecallpro::V1::Base.new(@client_api_integration)
          hcp_client = Integrations::HousecallPro::Base.new(@client_api_integration.credentials)

          data = {
            event:          hcp_client.parse_webhook(**params.to_unsafe_h),
            process_events: true,
            raw_params:     params
          }
          hcp_model.delay(
            run_at:              Time.current,
            priority:            DelayedJob.job_priority('housecallpro_process_job'),
            queue:               DelayedJob.job_queue('housecallpro_process_job'),
            user_id:             0,
            contact_id:          0,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'housecallpro_process_job',
            data:
          ).event_process(data)
        end

        respond_to do |format|
          format.json { render json: { status: 200, message: 'success' } }
          format.html { render plain: 'success', content_type: 'text/plain', layout: false, status: :ok }
        end
      end

      # (GET) show HouseCall Pro integration
      # /integrations/housecall
      # integrations_housecall_path
      # integrations_housecall_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/housecall/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/housecall/#{params[:card]}/index" : '' } }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('housecall')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Housecall Pro Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client
        @client = current_user.client
      end

      def client_api_integration
        return if (@client_api_integration = @client.client_api_integrations.find_or_create_by(target: 'housecall', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
